# musi

[getting started](doc/getting-started.md) - [embedding guide](doc/embedding.md)

> noun: game, art
>
> adjective: entertaining, artistic, amusing
>
> verb: to amuse, to play, to have fun
>
> *(from toki pona)*

musi is an artistic programming language for embedding into projects and
creating cohesive domain specific languages.

musi is pretty heavily inspired by lua, although still feels quite different
from it.

## artistic?

yes! musi is intended to be used to make domain specific languages, which means
that its syntax should be comfortable* to read.

> *comfort with a language's syntax is subjective. musi cannot be perfect, after
> all!

musi can be modified using the v api, although i am planning to make c bindings
so that musi can be added to basically any project, for any purpose!

**so why does that make it artistic?**

honestly, i do not know! i liked the name "musi" and because this language is
more of a "canvas" for people to use for their own purposes than a
general-purpose language, i felt like it could work well.

## installation

if you want to install musi for cli usage, you will need to compile from
source. luckily that is really easy:

```sh
git clone https://github.com/emmathemartian/musi
cd musi

# With clockwork
clockwork install

# Without clockwork
v -prod src/main.v
# executable is at src/main, you can symlink it somewhere on path now if you want:
ln -s $(pwd)/src/main ~/.local/bin/musi
```
