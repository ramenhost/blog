+++
title = "Typecasting pointers in C is arch-dependent"
description = "Typecasting pointers to a smaller datatype works only on little-endian architectures."

[taxonomies]
tags = ["programming"]
+++

For years, I've been confidently downcasting pointers after checking for value overflow. Today I learned that typecasting pointers to a smaller datatype works only on little-endian architectures. On big-endian systems, the pointer will reference the most significant bytes, leading to unexpected results. I realized this the hard way when this [PR](https://github.com/openssl/openssl/pull/24636) failed CI with flying colors.

{{ <image path="c-pointer-typecast.jpg" alt="C pointer typecasting issues with big-endian" /> }}
