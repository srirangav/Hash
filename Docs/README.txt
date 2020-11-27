README
------

Hash v. 1.1.8
By Sriranga Veeraraghavan <ranga@calalum.org>

About:

    Hash is a MacOSX application to generate and verify the
    hash, crc, or checksum of a file.  The following hash
    functions are supported:

    MD5
    SHA1
    SHA1 DC (SHA1 with collision detection / protection)
    SHA2 (SHA224, SHA256, SHA384, SHA512)
    SHA3/SHAKE (128, 224, 256, 384, 512)
    RIPEMD (160, 320)
    Whirlpool
    BLAKE (224, 256, 384, 512)
    BLAKE2 (BLAKE2S 256; BLAKE2B 256, 512)
    Skein (256-256, 512-256, 512-512, 1024-256, 1024-512)
    MD6 (256, 512)
    JH (224, 256, 384, 512)
    Groestl (224, 256, 384, 512)
    Tiger, Tiger2
    HAS-160
    Snefru (128, 256)

Installation:

    Copy Hash.app to /Applications (or wherever you prefer)

Supported MacOSX versions:

    v. 1.0.15 onwards     - 10.9+
    v. 1.0.14 and earlier - 10.6+

License:

    Please see LICENSE.txt

History:

    v. 1.1.8  - Build on Big Sur, add SHAKE128, SHAKE256
    v. 1.1.7  - Added support for checking the length of the
                verification hash
    v. 1.1.6  - Added a menu item to toggle lower case output
    v. 1.1.5  - Added support for Snefru (128, 256)
    v. 1.1.4  - Added SHA1 collision detection
    v. 1.1.3  - Added finder service to hash a selected file
    v. 1.1.2  - Added support for JH (224, 256, 384, 512),
                Tiger/Tiger2, BLAKE (224, 256, 384, 512),
                GROESTL (224, 256, 384, 512)
    v. 1.1.1  - Enabled MD6
    v. 1.1.0  - Added suport for dark mode
    v. 1.0.15 - Updated for app notarizing
    v. 1.0.14 - Enabled app sandbox and hardened runtime
    v. 1.0.12 - Added support for MD6 (256, 512)
    v. 1.0.11 - Added support for BLAKE2, Skein, SHA224,
                SHA384, SHA3
    v. 1.0.10 - Initial GitHub Release

References:

    MD5          - RFC 1321 (https://tools.ietf.org/html/rfc1321)
    SHA1         - https://en.wikipedia.org/wiki/SHA-1
    SHA1 DC      - https://github.com/cr-marcstevens/sha1collisiondetection
    SHA2         - https://en.wikipedia.org/wiki/SHA-2
    SHA3/SHAKE   - https://keccak.team/
                   https://en.wikipedia.org/wiki/SHA-3
                   https://www.di-mgt.com.au/sha_testvectors.html
    RIPEMD       - https://homes.esat.kuleuven.be/~bosselae/ripemd160.html
                   https://en.wikipedia.org/wiki/RIPEMD
    Whirlpool    - http://www.larc.usp.br/~pbarreto/WhirlpoolPage.html
                   https://en.wikipedia.org/wiki/Whirlpool_(hash_function)
    BLAKE        - https://131002.net/blake/
                   https://github.com/veorq/BLAKE
                   https://en.wikipedia.org/wiki/BLAKE_%28hash_function%29
                   https://asecuritysite.com/encryption/blake
    BLAKE2       - RFC 7693 (https://tools.ietf.org/html/rfc7693)
                   https://blake2.net/
                   https://github.com/BLAKE2/BLAKE2
                   https://en.wikipedia.org/wiki/BLAKE_(hash_function)#BLAKE2
    Skein        - http://www.skein-hash.info/
                   https://en.wikipedia.org/wiki/Skein_(hash_function)
    MD6          - https://groups.csail.mit.edu/cis/md6/
                   https://en.wikipedia.org/wiki/MD6
                   https://lib.rs/crates/md6
    JH           - https://www3.ntu.edu.sg/home/wuhj/research/jh/index.html
                   https://en.wikipedia.org/wiki/JH_(hash_function)
    Groestl      - https://www.groestl.info/
                   https://en.wikipedia.org/wiki/Gr%C3%B8stl
    Tiger/Tiger2 - https://www.cs.technion.ac.il/~biham/Reports/Tiger/
                   https://en.wikipedia.org/wiki/Tiger_(hash_function)
                   https://github.com/rhash/RHash
    HAS-160      - https://www.randombit.net/has160.html
                   https://github.com/rhash/RHash
    Snefru       - https://en.wikipedia.org/wiki/Snefru
                   https://github.com/rhash/RHash
