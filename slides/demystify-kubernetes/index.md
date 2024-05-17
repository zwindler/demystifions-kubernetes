---
marp: true
theme: gaia
markdown.marp.enableHtml: true
paginate: true
---

<style>

section {
  background-color: #fefefe;
  color: #333;
}

img[alt~="center"] {
  display: block;
  margin: 0 auto;
}
blockquote {
  background: #ffedcc;
  border-left: 10px solid #d1bf9d;
  margin: 1.5em 10px;
  padding: 0.5em 10px;
}
blockquote:before{
  content: unset;
}
blockquote:after{
  content: unset;
}
</style>

<!-- _class: lead -->

# Demystifying the Internal Components of Kubernetes ![height:55](../binaries/kubernetes_small.png)

---

## ~$ whoami

Denis Germain

-  Site Reliability Engineer ![height:40](../binaries/deezer-logo.png)
- French tech blogger : [blog.zwindler.fr](https://blog.zwindler.fr)*
<br/>

![width:35](../binaries/twitter.png) ![width:35](../binaries/Mastodon.png) [@zwindler(@framapiaf.org)](https://framapiaf.org/@zwindler)

**#geek** 👨‍💻 **#SF** 🤖👽 **#runner** 🏃‍♂️

![bg fit right:38%](../binaries/denis.png)

<br/>

**the slides are on the blog*

---

<!-- _class: lead -->

# Demystifying the Internal Components of Kubernetes ![height:55](../binaries/kubernetes_small.png)

---

<!-- _class: lead -->

# Questions 🚨

---

## "Kubernetes is ✨ **magic** ✨" 🤩 (no, it's not)

In reality :
- Manage **infrastructure with APIs** (& YAML)
- Applications lifecycle and scale management
- Native high availability
- **Super extensible**

![bg fit right:25%](../binaries/kubernetes_small.png)

---

## A few ![height:55](../binaries/kubernetes_small.png) notions

**Node** or **Worker** : the server running the **Pods**

**Pod** : Kubernetes compute unit. 
1-n containers sharing 0-n volumes and an IP address

![bg fit right:38%](../binaries/nodes-pods.png)

---

## Let's deploy an app!

3 APIs :
- [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 
(application)
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/) (loadbalancer)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) 
(reverse proxy)

![bg fit right:62%](../binaries/app.png)

---

## What does it look like in YAML?

![height:500](../binaries/deploy.yaml.png) ![height:500](../binaries/service.yaml.png) ![height:500](../binaries/ingress.yaml.png)

---

<!-- _class: lead -->

# Cool, but how does it runs really under the hood 🚗 ?

---

### I want to play a game

- I'm going to deploy a web server in V(lang) using YAML manifests (easy)


- BUT, we'll deploy before that a Kubernetes cluster, binary by binary first

<br/>

[github.com/zwindler/demystifions-kubernetes](https://github.com/zwindler/demystifions-kubernetes)

![bg fit right](../binaries/i-want-to-play-a-game-play-time.gif)

---

## API server

- Centralize the APIs (extensible)
- Abstract our infrastructure components

<br/>

![bg fit right:30%](../binaries/apis.png)

![width:800](../binaries/kube-architecture-1.png)

---

## etcd

- key value database
- distributed / fault-tolerant (raft)

<br/>

![bg fit right:25%](../binaries/etcd.png)

![width:800](../binaries/kube-architecture-1.png)

---

## It's time to D-D-D-D-D-DEMO !

![center width:600](../binaries/demo.png)

---

<!-- _class: lead -->

# "Scotty, I need more power"

---

## Controller Manager

Controllers are independant control loop softwares:
- Subscribe to events
- Act on events

![center width:800](../binaries/kube-architecture-2.png)

---

## A few controllers

- [ReplicationController](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/)
- *endpoints* controller
- *namespace* controller
- *ServiceAccounts* controller

But also :
- CRDs / operators
- storage providers (CSI)

![bg fit right:45%](../binaries/deployment.png)

---

## Let's add a **controller-manager**

![center width:600](../binaries/demo.png)

---

## Scheduler

How does Kubernetes know "where" to put a new **Pod**? 

- CPUs & RAM requests /  Affinity & anti-affinity / nodeSelector / taints & toleration ([see official documentation](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/))

![center width:800](../binaries/kube-architecture-3.png)

---

## Let's add a **scheduler**

![center width:600](../binaries/demo.png)

---


<!-- _class: lead -->

# Now we have a working **control plane**
# But where are the **Nodes**?!

---

## kubelet

- Send/receive **Node** information
- Controls **container runtime**
  - adds/deletes **Pods**
  - checks **Pods** health
  <br/>

[Official documentation - kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

![bg right:45% fit](../binaries/kube-architecture-4.png)

---

## Container runtime

To run the containers in the pods, we need a **container runtime**

At first, ![height:40](../binaries/docker.png) 
(`dockershim` is unsupported in 1.24)

Often replaced by `containerd` now, lot's of alternatives!

![bg right:45% fit](../binaries/kube-architecture-4.png)

---

## Internal network ![height:60](../binaries/kubernetes_small.png)

![height:40](../binaries/kubernetes_small.png) uses `iptables`, `ipvs`, ou `eBPF` to *simulate* the (*virtual*) network

![width:300 center](../binaries/thereisnospoon.jpeg)

> There is no IP

![bg fit right:40%](../binaries/kube-network.png)

---

## CNI plugin

- **C**ontainer **N**etwork **I**nterface
- Kubernetes internal network
- CNI plugins = implementations of the CNI
  - ![height:50](../binaries/calico.png)
  - ![height:50](../binaries/cilium.png) 
  - ![height:50](../binaries/flannel.png)

![bg right:45% fit](../binaries/kube-architecture-5.png)

---

## kube-proxy (optional)

Component responsible of creating/managing dynamically `iptables` rules to route trafic from **Services** to living **Pods**

![center](../binaries/iptables-rules.png)

---

## We only need one more thing, I promise 🙃 

![center width:600](../binaries/demo.png)

---

## IngressController

Routing HTTP(S) requests
- **IngressController** is a third party component managing **Ingress**

Note: **Ingress API** is being replaced by tge **Gateway API** (more powerful and more agnostic)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)

![bg fit right:40%](../binaries/ingress.yaml.png)

---

## End of the demo

![center width:600](../binaries/demo.png)

---

## ![height:40](../binaries/kubernetes_small.png) is "only"

- an API server
- a scheduler
- control loops
- a *container runtime*
- a virtual network

![bg fit right:45%](../binaries/kube-architecture-5.png)


![width:42](../binaries/twitter.png) ![width:35](../binaries/Mastodon.png) [@zwindler(@framapiaf.org)](https://framapiaf.org/@zwindler)

![height:50](../binaries/denis.png) Slides and sources on [blog.zwindler.fr/conférences](https://blog.zwindler.fr/conf%C3%A9rences/)

---

<!-- _class: lead -->

# Sources

---

## Sources / articles

- Sources
  - [github.com/zwindler/demystifions-kubernetes](https://github.com/zwindler/demystifions-kubernetes)
- Kubernetes "the hard way"
  - [github.com/kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Medium.com - Madhavan Nagarajan - Kubernetes Internals: Architecture Overview](https://medium.com/@itIsMadhavan/kubernetes-internals-architecture-overview-2301ce80df32)
- [github.com/shubheksha/kubernetes-internals](https://github.com/shubheksha/kubernetes-internals)
- [K8s: A Closer Look at Kube-Proxy](https://betterprogramming.pub/k8s-a-closer-look-at-kube-proxy-372c4e8b090)

---

<!-- _class: lead -->

# Backup slides

---

## Talks / conferences on the same topic

- Carson Anderson - Kubernetes Deconstructed
  - [Version talk Kubecon](https://www.youtube.com/watch?v=90kZRyPcRZw)
  - [Version talk complet](https://www.youtube.com/watch?v=JhTaue0C1kk)

- Jérôme Petazzoni - Dessine moi un cluster
  - [github.com/jpetazzo/dessine-moi-un-cluster](https://github.com/jpetazzo/dessine-moi-un-cluster)
  - [Talk Lisa19](https://www.youtube.com/watch?v=3KtEAa7_duA)

- [Kubernetes Design Principles: Understand the Why](https://www.youtube.com/watch?v=ZuIQurh_kDk)


---

## What is a **container** ?

**It's a box!** 😂

- Process (or software)
- Run by "runtime"
- Isolated from other process on host
- Not only ![height:30](../binaries/docker.png)!
(microVMs, container ![height:30](../binaries/windows.png), WASM ...)

![bg fit left:40%](../binaries/container.png)

---

## What is **Kubernetes**?

- Container orchestrator
- Inspired by a Google production tool
- Open sourced and given to the CNCF in 2015
- *Won* the "orchestrator war"
  - Docker swarm ![height:55](../binaries/docker-swarm.png)
  - Mesos Marathon ![height:55](../binaries/marathon.png)

![bg right:25% fit](../binaries/kubernetes_small.png)
