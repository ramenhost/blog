+++
title = "Using dynamic DNS for home servers"
description = "Exposing a local port to the internet with dynamic DNS."

[taxonomies]
tags = ["home-lab", "networking"]
+++

It is often joked about sharing localhost URL with others, but there are scenarios where exposing a local port to the internet is genuinely useful. For instance, I can run a [Plex media server](https://www.plex.tv/personal-media-server/) at home instead of paying for Google photos, also stream my downloaded movies/shows from any device. Many internet providers use [CGNAT](https://en.wikipedia.org/wiki/Carrier-grade_NAT) for IPv4, which combined with NAT in home routers creates a double NAT. While this is cheaper for ISPs and also beneficial for security, it complicates exposing your home servers to internet.

With the advent of IPv6, things are changing. ISPs are now providing public IPv6 addresses. Since IPv6 addresses are plenty, NAT is typically not used. The remaining challenge is that IPv6 addresses are typically dynamic and change frequently. This is where dynamic DNS comes into play. By obtaining a domain name and running a dynamic DNS software, you can keep the DNS record updated whenever your home IPv6 address changes. This allows you to access your home servers using a static domain name instead of the ever-changing IP address.

> [!CAUTION]
> Exposing home servers to internet can heavily undermine security of your home network. Not recommended unless you know what you are doing.

Here is my setup of Plex media server with dynamic DNS [https://gist.github.com/ramenhost/9d26175abcbebf5c739e8de7d3ec3d13](https://gist.github.com/ramenhost/9d26175abcbebf5c739e8de7d3ec3d13)
