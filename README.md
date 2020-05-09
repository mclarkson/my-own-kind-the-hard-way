# My Own Kind

![](docs/images/mokctl-demo.gif)

## Summary

Build a conformant kubernetes cluster in containers, on Linux, using docker only, by hand, from scratch, for learning.

### Try mokctl

Install [Docker](https://docs.docker.com/get-docker/) if you don't have it already.

Take note of the [Status](#status) above and the [Releases](https://github.com/mclarkson/my-own-kind/releases) page.

#### For Non-Linux Operating Systems

Paste the following alias into your teminal:

```bash
alias mokctl='docker run --rm --privileged -ti -v /var/run/docker.sock:/var/run/docker.sock -v ~/.mok/:/root/.mok/ -e TERM=xterm-256color mclarkson/mokctl'
```

Then use mokctl:

```bash
mokctl build image

mokctl create cluster myk8s 1 0

export KUBECONFIG=~/.mok/admin.conf

kubectl get pods -A

kubectl run -ti --image busybox busybox sh
```

See: [Mokctl on Docker Hub](https://hub.docker.com/r/mclarkson/mokctl).

#### For Linux Operating Systems

Work is progressing on getting `podman` working with `mokctl` - See [Install Linux](/docs/install-linux.md)

## Status

**Mokctl Utility**

| OS        | Termnal          | Status |
| --------- | ---------------- | ------ |
| Fedora 31 | Gnome Terminal   | Works  |
| Mac OS    | Default terminal | ?      |
| Windows   | Cygwin           | ?      |

## Contributing

Please check the 'Help Wanted' issues if you fancy helping.

All types of contributions are welcome, from bug reports, success stories, feature requests, fixing typppos, to coding. Also check the [CONTRIBUTING.md](/CONTRIBUTING.md) document.

## License

Apache 2 - You can do what you like with the software, as long as you include the required notices. This permissive license contains a patent license 
from the contributors of the code. See: [tl;drLegal](https://tldrlegal.com/license/apache-license-2.0-%28apache-2.0%29) for a summary. Full text is in the LICENSE file.
