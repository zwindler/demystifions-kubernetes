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

# Démystifions le fonctionnement interne de Kubernetes ![height:55](binaries/kubernetes_small.png)

---

## ~$ whoami

**Denis Germain** 👨‍💻🧙🔥🏃‍♂️

- *unemployed tinkerer*
- Blog tech (et +) : [blog.zwindler.fr](https://blog.zwindler.fr)*
- Membre de [BDX I/O](https://bdxio.fr/)
<br/>

![width:35](binaries/twitter.png) ![width:32](binaries/Mastodon.png) ![width:32](binaries/logo-bsky.jpg) [@zwindler(@framapiaf.org)](https://framapiaf.org/@zwindler)

![bg fit right:39%](binaries/denis.png)

<br/>

![](binaries/cc-by-sa-40.png)

---

## Pourquoi Kubernetes 
## (et pourquoi ce talk ) ?

- Haute disponibilité native
- Gestion du cycle de vie des applications et de leur mise à l'échelle
- Gestion de l'infra avec des APIs / du YAML
- Extensibilité

* **C'est✨ auto-magique** ✨ 🤩 (nope ![height:68](binaries/grumpy.png))

![bg fit right:25%](binaries/kubernetes_small.png)

---

<!-- _class: lead -->

# Comment ça marche,
# sous le capot 🚗 ?

---

### But du jeu

- Déployer un serveur web en V(lang) à l'aide de manifests YAML
- Déployer Kubernetes **1.31.0-alpha.0** (l'amour du risque), binaire par binaire

<br/>
<br/>
<br/>

[github.com/zwindler/demystifions-kubernetes](https://github.com/zwindler/demystifions-kubernetes)

![bg fit right:35%](binaries/i-want-to-play-a-game-play-time.gif)

---

## En YAML, ça donne quoi, un app dans kube ?

![height:500](binaries/deploy.yaml.png) ![height:500](binaries/service.yaml.png) ![height:500](binaries/ingress.yaml.png)

---

## It's time to D-D-D-D-D-DEMO !

![center width:600](binaries/demo.png)

---

## Au final, ![height:40](binaries/kubernetes_small.png), c'est juste

- un serveur d'API
- un ordonnanceur
- des boucles de contrôles
- un *container runtime*
- un réseau virtuel

![bg fit right:45%](binaries/kube-architecture-5.png)


![width:42](binaries/twitter.png) ![width:35](binaries/Mastodon.png) [@zwindler(@framapiaf.org)](https://framapiaf.org/@zwindler)

![height:50](binaries/denis.png) Slides et sources sur [blog.zwindler.fr/conférences](https://blog.zwindler.fr/conf%C3%A9rences/)

---

<!-- _class: lead -->

# Backup slides

---

## C'est quoi, un **container** ?

**C'est une boite !**

- Processus (ou logiciel)
- Exécuté par un "runtime"
- Isolé des autres processus de l'hôte
- Pas forcément ![height:30](binaries/docker.png) !
(microVMs, container ![height:30](binaries/windows.png), WASM ...)

![bg fit left:40%](binaries/container.png)

---

## C'est quoi, **Kubernetes** ?

- Orchestrateur de containers
- Inspiré par un outil interne de Google
- Open sourcé et donné à la CNCF en 2015
- A *gagné* la "guerre des orchestrateurs" 
  - Docker swarm ![height:55](binaries/docker-swarm.png)
  - Mesos Marathon ![height:55](binaries/marathon.png)

![bg right:25% fit](binaries/kubernetes_small.png)

---

## Quelques notions ![height:55](binaries/kubernetes_small.png)

**Node** ou **Worker** : Serveur informatique qui héberge les **Pods**

**Pod** : Unité de compute Kubernetes. Ensemble de containers qui partagent une IP et des volumes.

![bg fit right:40%](binaries/nodes-pods.png)

---

## Déployer une application

3 APIs :
- [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) 
(application)
- [Service](https://kubernetes.io/docs/concepts/services-networking/service/) (loadbalancer)
- [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) 
(reverse proxy)

![bg fit right:62%](binaries/app.png)

---

## API server

- Centralise les APIs disponibles (extensible)
- Abstractions de l'infra

<br/>

![bg fit right:30%](binaries/apis.png)

![width:800](binaries/kube-architecture-1.png)

---

## etcd

- Base de données clé/valeur
- Distribuée / fault-tolerant (raft)

<br/>

![bg fit right:25%](binaries/etcd.png)

![width:800](binaries/kube-architecture-1.png)

---

## Controller Manager

Les controllers sont des boucles de contrôles :
- Abonnement à des événements
- Actions en conséquences

![center width:800](binaries/kube-architecture-2.png)

---

## Quelques controllers

- [ReplicationController](https://kubernetes.io/docs/concepts/workloads/controllers/replicationcontroller/)
- *endpoints* controller
- *namespace* controller
- *ServiceAccounts* controller

Mais aussi :
- CRDs / operators
- Fournisseurs de stockage (CSI)

![bg fit right:45%](binaries/deployment.png)

---

## Ajoutons un **controller-manager**

![center width:600](binaries/demo.png)

---

## Scheduler

Où positionner un nouveau **Pod** en fonction de contraintes :

- Réservations CPUs & RAM /  Affinité & anti-affinité / nodeSelector / taints &toleration ([doc officielle](https://kubernetes.io/docs/concepts/scheduling-eviction/kube-scheduler/))

![center width:800](binaries/kube-architecture-3.png)

---

## Ajoutons un **scheduler**

![center width:600](binaries/demo.png)

---


<!-- _class: lead -->

# Le **control plane** est OK
# Mais on a toujours pas de **Nodes** !

---

## kubelet

- Envoie/réception des informations sur le **Node**
- Pilotage du **container runtime**
  - ajout/suppression de Pods
  - surveillance de l'état de santé des **Pods**
  <br/>

[Documentation officielle - kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/)

![bg right:45% fit](binaries/kube-architecture-4.png)

---

## Container runtime

Pour exécuter le(s) container(s) du Pod, il faut un **container runtime**

Historiquement, ![height:40](binaries/docker.png) 
(`dockershim` plus supporté depuis Kubernetes 1.24)

Souvent `containerd`, mais il y a plein d'alternatives !

![bg right:45% fit](binaries/kube-architecture-4.png)

---

## Réseau interne ![height:60](binaries/kubernetes_small.png)

On utilise `iptables`, `ipvs`, ou `eBPF` pour *simuler* le réseau (*virtuel*)

![width:300 center](binaries/thereisnospoon.jpeg)

> Cette IP **n'existe pas**, Néo

![bg fit right:40%](binaries/kube-network.png)

---

## CNI plugin

- **C**ontainer **N**etwork **I**nterface
- Réseau interne de Kubernetes
- CNI plugins = implém. du CNI
  - ![height:50](binaries/calico.png)
  - ![height:50](binaries/cilium.png) 
  - ![height:50](binaries/flannel.png)

![bg right:48% fit](binaries/kube-architecture-5.png)

---

## kube-proxy (optionnel)

Gérer les règles `iptables` dynamiques pour router le traffic depuis les **Services** vers les **Pods** qui sont vivants

![center](binaries/iptables-rules.png)


---

## Promis, il manque plus qu'un bout 🙃 

![center width:600](binaries/demo.png)

---

## IngressController

Router des requêtes HTTP(S)
- l'**IngressController** est un logiciel tiers qui gère des **Ingress**

Note: **Ingress API** en cours de remplacement par la **Gateway API** (plus puissante et plus agnostique)
- [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/)

![bg fit right:40%](binaries/ingress.yaml.png)



---

<!-- _class: lead -->

# Sources

---

## Dépôts / articles

- Sources pour ce talk
  - [github.com/zwindler/demystifions-kubernetes](https://github.com/zwindler/demystifions-kubernetes)
- Kubernetes "the hard way"
  - [github.com/kelseyhightower/kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Medium.com - Madhavan Nagarajan - Kubernetes Internals: Architecture Overview](https://medium.com/@itIsMadhavan/kubernetes-internals-architecture-overview-2301ce80df32)
- [github.com/shubheksha/kubernetes-internals](https://github.com/shubheksha/kubernetes-internals)
- [K8s: A Closer Look at Kube-Proxy](https://betterprogramming.pub/k8s-a-closer-look-at-kube-proxy-372c4e8b090)


---

## Talks / conférences sur le même sujet

- Carson Anderson - Kubernetes Deconstructed
  - [Version talk Kubecon](https://www.youtube.com/watch?v=90kZRyPcRZw)
  - [Version talk complet](https://www.youtube.com/watch?v=JhTaue0C1kk)

- Jérôme Petazzoni - Dessine moi un cluster
  - [github.com/jpetazzo/dessine-moi-un-cluster](https://github.com/jpetazzo/dessine-moi-un-cluster)
  - [Talk Lisa19](https://www.youtube.com/watch?v=3KtEAa7_duA)

- [Kubernetes Design Principles: Understand the Why](https://www.youtube.com/watch?v=ZuIQurh_kDk)
