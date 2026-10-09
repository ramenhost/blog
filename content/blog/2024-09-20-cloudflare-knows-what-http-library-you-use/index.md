+++
title = "Cloudflare knows what http library you use"
description = "A look into how Cloudflare uses TLS fingerprinting to detect and block certain HTTP libraries like aiohttp."

[taxonomies]
tags = ["programming", "networking"]
+++

In X, [@zoriya_dev](https://x.com/zoriya_dev) shared an issue where an API request was blocked by Cloudflare when using Python's `aiohttp` library, while the same request worked fine when using curl or the `requests` library. People got together in replies to investigate the issue.
<blockquote><p lang="en" dir="ltr">here is the python code (that gets cloudflare blocked)<br>the curl requests (that works)<br><br>and the netcat to print requests (by changing https://thexem by http://localhost), first is python second is curl <a href="https://t.co/eJZydIRbkK">https://t.co/eJZydIRbkK</a> <a href="https://t.co/8TSDb7WjMs">pic.twitter.com/8TSDb7WjMs</a></p>&mdash; Zoe Roux (@zoriya_dev) <a href="https://twitter.com/zoriya_dev/status/1837039528399212793?ref_src=twsrc%5Etfw">September 20, 2024</a></blockquote>

Initial analysis suggested that Cloudflare was blocking requests based on the User-Agent header. However, this theory was quickly disproven as the User-Agent header was identical in both `aiohttp` and `curl` requests. Even after ensuring that the entire HTTP request was the same for both libraries, the issue persisted. This indicated that the detection mechanism was operating at a lower level, likely involving TLS records.

Using Wireshark, I discovered that the TLS extensions differed between `aiohttp` and `curl`. By adding any single TLS extension to `aiohttp`, the block was bypassed, effectively disrupting the blacklisted fingerprint.

{{ <image path="cf-tls-fingerprint.jpg" alt="Adding TLS extension to bypass TLS fingerprinting" /> }}

TLS fingerprinting is a common technique used by Cloudflare and other services to detect bots and malicious traffic. Cloudflare offers varying degrees of protection that can be configured by the domain owner. In this case, it is possible that the domain was put in a higher protection level where TLS fingerprint of `aiohttp` is blacklisted.
