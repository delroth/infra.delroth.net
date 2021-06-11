This repository contains the NixOS configuration for the machines I run at home
and the various servers I rent around the world. Multiple VPS, one large Hetner
dedicated box, a laptop, an ARMv8 file server (with custom kernel and modules),
and more!

I used to have a disclaimer saying "I don't know what I'm doing, I wouldn't
recommend looking at this". After about 2 years of iterating on this
configuration I think I'm now happy enough with the state to recommend people
to have a look for inspiration and maybe as an example of how to write a
complex Nix configuration for an heterogeneous set of machines.

## Structure

The entry point to the configuration is in the `deployments/` directory. I use
`morph` to build and push the configuration over SSH to my various machines.

The shared configuration that is designed to be reusable across machines is
organized like this:

* `common`: contains configuration that should apply everywhere as a baseline.
  Some exceptions there: for example, GUI related configuration only applies to
  machines that are declared as having a graphical terminal, etc.

* `roles`: modules that define a specific thing that I want a machine to be
  doing. For example, "email server" or "file server" or "blackbox prober".
  Some of these can be used on multiple machines, some are kind of designed to
  be "unique" across the whole fleet (but nothing enforces it right now).

* `pkgs`: a common package overlay applied to all machines. I use this for
  things that are pending upstreaming or that I don't think should be
  upstreamed.

* `services`: similar to `pkgs`, a place for NixOS modules that I haven't
  upstreamed.

Machine specific configuration is scoped to the `machines` directory.

Secrets are stored in the `secrets` directory, encrypted with `git-crypt`.

## Caveats

I made the explicit design choice that my machines are single-user, and that
lateral movement across machines isn't something I'm focusing on strongly. This
leads to some design simplifications: for example, I'm completely happy with
secrets in the Nix store.

## Misc notes

I use a few patches to nixpkgs that aren't upstreamed because I never bothered
cleaning them up, so blindly copy-pasting might not result in everything
working properly.

If you've used this as a reference for your own configuration, if you need any
help understanding something, or if you see a potential for improvement, feel
free to contact me and give me feedback! Either as an issue on this repo, or:

- @delroth:delroth.net on Matrix
- @delroth_ on Twitter
- delroth@gmail.com by email
