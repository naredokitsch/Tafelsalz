# Tafelsalz

The main idea of this project is to provide usable but safe cyryptographic operations. Usability does not mean, that the minimum effort is required to integrate an operation. Minimum effort might result in single lines of code that you write… et voilà your system is secure. No. It means that it requires only the minimum of knowledge to do something wrong.

The [*libsodium*](https://libsodium.org) project has a similar goal, but does not leverage the features available in modern programming languages such as Swift. The *libsodium* library is based on [NaCl](https://nacl.cr.yp.to) whoose authors discussed the security issues related to cryptographic APIs that are too complicated and error-prone[^1] – or as Matthew Green[^2] put it:

> OpenSSL is the space shuttle of crypto libraries. It will get you to space, provided you have a team of people to push the ten thousand buttons required to do so. NaCl is more like an elevator — you just press a button and it takes you there. No frills or options.
>
> I like elevators.

To stay with the analogy: *libsodium* and *NaCl* prevent any accidents to happen if you press a button for some floor which isn't there. This project tries to prevent the button being there in the first place.

This is achieved by leveraging programming language features in a way that an operation cannot be called with invalid or insecure parameters. Every such call should be prevented at compile time already.

Note that the goal is not to prevent malicious attackers to circumvent the established protection mechanisms by the programming language features but to prevent accidental misuse of cryptographic APIs.

⚠️ **WARNING**: This project is still work in progress and the API is highly unstable. It is recommended to use a more stable library for the time being, such as [jedisct1/swift-sodium](https://github.com/jedisct1/swift-sodium).



[^1]: D. J. Bernstein, T. Lange, and P. Schwabe, **The Security Impact of a New Cryptographic Library** in *Progress in Cryptology – LATINCRYPT 2012 – 2nd International Conference on Cryptology and Information Security in Latin America, Santiago, Chile, October 7-10, 2012. Proceedings* (A. Hevia and G. Neven, eds.), pp. 159–176
[^2]: M. Green, **The anatomy of a bad idea**, 2012, URL: http://blog.cryptographyengineering.com/2012/12/the-anatomy-of-bad-idea.html