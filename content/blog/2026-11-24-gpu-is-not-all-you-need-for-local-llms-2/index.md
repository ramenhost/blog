+++
title = "GPU is not all you need for local LLMs - Part 2"
description = "Local LLM prefill speedup by spliting GEMM across GPU, CPU and ANE in Macbook M4 Air"

[taxonomies]
tags = ["llm", "performance"]
+++

_This is part 2 of a two part series. Read [part 1](../gpu-is-not-all-you-need-for-local-llms/) to understand unique features needed in local LLM inference engines compared to cloud inference._

> [!NOTE]
> _This experimental work is a result of me driving LLMs with my intuitions. Under Gemini 4 Argon's oversight, Gemini 4 Hydrogen and Deepseek V4.1 Flash wrote all the code and benchmarks. Total cost was \~\$50 with API pricing. The term "we" in this post refers to me and LLM models I used._

Local LLM inference engines often only utilize GPUs for large models. Let’s see the compute power in Apple Silicon apart from the GPU. We have something called a neural engine. A closer look at the CPU will reveal the presence of AMX (Apple Matrix Coprocessor) inside it. AMX is yet another accelerator for working with matrices.

![Block diagram of Apple's Unified Memory Architecture](unified-memory-architecture.avif)
_Source:_ [_What Is Unified Memory on Your Mac and How Does It Work?_](https://www.makeuseof.com/what-is-unified-memory/)

The AMX and Apple Neural Engine (ANE), which I paid for, sit idle while the GPU saturates during prefill compute. 
[Uzu](https://trymirai.com/inference-runtime) claims the [best token generation speed](https://trymirai.com/metrics) in Apple Silicom because of its [speculative decoding](https://trymirai.com/blog/speculative-decoding-in-uzu). But its input prompt processing (prefill) was painfully slow in my base M4 chip. Based on its published [metrics](https://trymirai.com/metrics), prefill speed was already on-par with the alternatives. I decided to implement split prefill in Uzu by summoning a few LLMs. Split prefill is where the prefill compute work is split across multiple accelerators - GPU, CPU and ANE in Apple Silicon.

Long story short, prefill got a huge speedup by sharing the work with CPU and the Apple Neural Engine (ANE). For every large matrix-matrix multiplication, we made each engine work on its own share of the matrix and write output to a shared memory. The GEMM is split along the output-channel dimension such that all three engines read the same input activation matrix and write to disjoint column offsets with zero cross-device communication. Because of the unified memory in Apple Silicon, this heterogeneous GEMM split results in zero cross-device copies. Having said that, there is an overhead of storing layout transposes to match the ANE’s requirement.

{{ <image path="gemm-column-split.png" alt="Illustration showing how a matric multiplication is split across the output columns" /> }}
_AI generated image_

The split ratio must be carefully engineered so that all three engines complete work at the same time and not get blocked on others. For finding the optimal split ratio, there is an initial tuning step that runs at model load time. 

The CPU split uses AMX via [BNNS](https://developer.apple.com/documentation/accelerate/bnns) API. Apple’s ANE has somewhat a closed API designed only for running complete neural network inference. ANE does not expose APIs to perform custom matrix multiplications. Thanks to [this work](https://maderix.substack.com/p/inside-the-m4-apple-neural-engine) of reverse engineering the ANE.

With our [experimental patch](https://github.com/trymirai/uzu/commit/731a2b42b329bce8a8f3a12bca83f2492f7d6784#diff-e7f8d63f4ea6e2824cae636b22073db12d3c2d2cb05e6884c6823e07e1e1ae4d) on Macbook M4 Air (24GB) running Qwen3.5-9B (Mirai M-quantized, 4-bit) model, we see _2.78x_ prefill speedup on 1024 and 2048 token prompts (and up to _2.89x_ on real summarization tasks). This directly converts to faster Time to First Token (TTFT).

{{ <image path="uzu-gemm-split-results-by-mode.png" alt="Performance numbers of GEMM split by split mode" /> }}
{{ <image path="uzu-gemm-split-results-by-benchmarks.png" alt="Performance numbers of GEMM split by summarization benchmarks" /> }}
{{ <image path="uzu-gemm-split-results-by-prompt-lengths.png" alt="Performance numbers of GEMM split by controlled prompt lengths" /> }}

There are challenges shipping the prefill split feature. These are also the reasons it is not found in many popular inference engines, I assume.

- The prefill split ratio is heavily hardware dependent. This requires a tuning phase to identify split ratios that provide peak prefill throughput.
- A major performance benefit comes from the Apple Neural Engine (ANE). The ANE is designed for running an entire small model inside it using the Core ML API. ANE does not have a documented interface for submitting GEMM operations. This work uses private APIs and submits GEMM as 1x1 convolution operations.
- All 3 engines share the same thermal envelope. Fortunately, short prefill bursts complete before thermal throttling kicks in. The benchmark numbers were captured by letting the system cool below 60°C between each prefill run. Having said that, the ANE is very power efficient and its utilization reduces the total energy spent.
- Weights are pre-dequantized for CPU and ANE, increasing the memory footprint of the model (up to 55% in my experiments).
- Newer M5 chips have matrix multiplication units called Neural Accelerator (NAX) built right into the GPU cores. This will likely change the numbers to make prefill splitting less attractive or even provide negative performance gain.

While it is nothing novel, the experiment was a good learning experience. I don't plan to submit this upstream, rather I use it as a makeshift solution for Qwen family models in my Macbook without NAX.
