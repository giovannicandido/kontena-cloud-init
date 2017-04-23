# Roteiro para criação de um cluster docker

Eu criei uma apresentação no youtube sobre o cluster, que pode ser no link abaixo:

[![Apresentação em vídeo](https://img.youtube.com/vi/7uJzcy7Ls-s/0.jpg)](https://www.youtube.com/watch?v=7uJzcy7Ls-s)


## Prerequisitos

1. Um virtualizador (virtualbox, vmware, kvm, esxi, etc...)
2. Conexão com internet
3. Memória suficiente para 3 máquinas virtuais, mínimo 3Gb RAM sobrando.
4. Já conhece o básico sobre docker
5. Não tem medo de linha de comando e conhece pelo ao menos o básico de linux
6. Consegue adaptar os exemplos para windows, todos estão como um host linux
7. Sabe conectar via ssh em servidores com chave pública.

Ou seja, você é um sysadmin, ou aspirante a sysadmin :-)

Vamos usar máquinas virtuais para criar um cluster de dados docker que será orquestrado pelo software http://kontena.io

Kontena pode ser instalado em diversos sistemas operacionais linux, desde que esses rodem docker. No entando vamos utilizar
o [coreos](https://coreos.com), pela simplicidade e facilidade de escalar para produção. Esse também é o SO padrão para
o cluster kontena quando se utiliza o sua linha de comando para criar rapidamente o cluster.

Há duas alternativas para criar o cluster:

1. Deixar o client de linha de comando kontena criar o cluster automaticamente.
2. Criar o cluster passo a passo.

A primeira opção é a mais rápida, e você pode ter o cluster em poucos minutos rodando 
(dependendo da velocidade de sua conexão para baixar as virtual machines), fique livre para escolher a que achar melhor.

Nas duas opções iremos precisar do utilitário de linha de comando para controlar o cluster, vá em frente e instale-o: http://kontena.io/docs/getting-started/installing/cli.html

# Primeira opção: VirtualBox com 4 linhas de comando

A primeira forma utiliza VirtualBox e Vagrant.

```
kontena plugin install vagrant
kontena vagrant master create
kontena grid use test-grid # ou kontena grid create --initial-size=1 test-grid
kontena vagrant node create
```
Você terá um master e um no, e eles já devem estar comunicando entre si. Verifique com o comando:

```
kontena node ls
```
Um nó deve aparecer.

Crie pelo ao menos mais um nó.

**Nota** Recomendo 512MB de memória para o master e pelo ao menos 1G para cada nó.

Instruções oficiais em: http://kontena.io/docs/getting-started/installing/vagrant.html

# Segunda opção: Faça você mesmo

Irei detalhar como criar o cluster de forma rápida, mas manual, para você que quer ter controle sobre tudo. Essas instruções servem para qualquer virtualizador, e também para certos fornecedores cloud.

Em alto nível o que se deve fazer é:

1. Instale o coreos e chame essa máquina de master.
2. Instale quantos nós forem necessários. Nota: Não clone, faça uma nova instalação. O kontena usa certos estados da máquina como o docker id, 
que se forem duplicados vai haver problemas com o cluster.
3. Crie o cloud-init iso para o master e monte como cdrom
4. Crie o cloud-init para os nós e monte como cdrom
5. Teste o cluster

Nota: Para quem nunca usou o coreos, a instalação do kontena é feita nos passos 3 e 4

## Passo 1 - Instalação da maquina master

Há diversas opções, desde dar boot com a imagem ISO e fazer a instalação, até importar uma imagem. Vamos importar a imagem.

Siga os tutoriais abaixo para seu ambiente, ignorando a parte de cloud-init pois vamos fazer isso no próximo passo (é interessante ler pois explica o que é).

**VirtualBox:** https://coreos.com/os/docs/latest/booting-on-virtualbox.html

**VMware:** https://coreos.com/os/docs/latest/booting-on-vmware.html

**ISO** https://coreos.com/os/docs/latest/installing-to-disk.html

Recomendações: Recomendo que a máquina virtual deva estar em NAT, (vmware importa com padrão bridge), pois é preciso acesso a internet para instalar o kontena, e uma rede entre as máquinas.

Também recomendo que o IP das máquinas seja fixo, isso vai evitar dor de cabeça depois, mas não é crítico. Uma maneira de fazer isso no VMware é editar o DHCP para entregar sempre o mesmo IP para máquina. ([vmware](https://www.vmware.com/support/ws55/doc/ws_net_advanced_ipaddress.html)), outra opção interessante é modificar o cloud-init para ter um ip fixo para cada vm.

Quando terminar de importar ou instalar a máquina, você não vai ter como logar na mesma. Isso é por design, e vamos adicionar nossa chave SSH nela por cloud-init.

## Passo 2 - Instalação dos nós

Repita o passo 1 para cada nó que for criar

## Passo 3 - Cloud init para master

Aqui está o pulo do gato se tratando de coreos. O interessante é que em um ambiente de núvem, você vai ter sua imagem do coreos mínima, e no boot da máquina ela lê
as instruções do cloud-init e se configura, aqui você pode fazer o que quiser.

Eu criei scripts que vão ajudar a gerar o cloud-init mais rápido, estão em https://github.com/giovannicandido/kontena-cloud-init

Como tudo na vida, temos opções: Você pode seguir o guia oficial do kontena em: http://kontena.io/docs/getting-started/installing/coreos.html
E também pode usar os scripts que criei, que foram baseados no guia oficial. Em todo caso você estará bem servido :-)

Recomendo que siga os dois, assim você vai entender melhor como meu script funciona.

1. Edite o arquivo **master/config-drive/openstack/latest/user_data**. 
   
   a) Adicione sua chave SSH pública. [Como gerar?](https://kb.iu.edu/d/aews)

   b) Opcional: Gere sua chave KONTENA_VAULT_KEY e KONTENA_VAULT_IV e edite o arquivo *user_data*:  `cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1`

   c) Opcional: Gere um certificado SSL para master e edite o arquivo *user_data*

2. Gere o iso do cloud init: `./generate.sh master`. Um arquivo **master-configdrive.iso** será gerado na pasta do script
3. Monte o iso como cdrom da máquina virtual no boot.
4. Ligue a máquina

Com o kontena instalado, use o CLI para logar e criar uma _grid_

```
export SSL_IGNORE_ERRORS=true 
kontena master login --name virtual --code admin https://master_ip
kontena grid create test
```

Nota: SSL_IGNORE_ERRORS=true força o CLI a conectar no master com um certificado auto assinado

Nota 2: OK, se está usando o certificado e as chaves que eu crei para testes, mas saiba que eu (e toda internet) pode hackear seu cluster, 
não se esqueça de criar o seu em produção ;-)

Nota 3: Não consegue autenticar pois o _code_ está errado? Instruções para resetar no final desse arquivo

## Passo 4 - Cloud init para nós

Você vai precisar do token do grid que criou no passo anterior.

```
 kontena grid show --token test 
```

Você pode editar o arquivo desse repositório, ou gerar um novo.

Para gerar um arquivo novo:

```
kontena grid cloud-config <grid name> > user_data
mv user_data nodes/config-drive/openstack/latest/
```

Edite o arquivo, adicione suas chaves ssh e coloque a configuração: `hostname: node`. Verifique se a configuração **KONTENA_PEER_INTERFACE** está correta

Para editar o aquivo existente:

1. Edite o arquivo **nodes/config-drive/openstack/latest/user_data**.
   
   a) Adicione sua chave SSH pública.
   
   b) Edite KONTENA_URI e KONTENA_TOKEN

2. Gere o iso do cloud init: `./generate-nodes.sh 2`. Dois arquivos iso serão gerados. (você também pode usar `./generate.sh nodes node1` para gerar um nó)
3. Monte o iso como cdrom da máquina virtual no boot.

Nota: KONTENA_URI é o ip ou DNS do master. Use _https_ se deixou o certifico ou se criou um certificado ao configurar o cloud-init do master, caso contrário _http_

Nota 2: `./generate-nodes.sh 1000` vai gerar 1000 arquivos iso um para cada nó. Legal não acha? O problema é montar esses iso e criar as 1000 máquinas virtuais rsrsrs

## Passo 5 - Teste o cluster

Seu cluster deve estar online com os nós que criou.

Vamos brincar um pouco:

```
kontena node ls
kontena grid health
kontena node show node1
kontena service create -p 80:80 nginx nginx:latest
kontena service show nginx
```

Abra um navegador no ip do nó onde o nginx está rodando e verifique seu funcionamento

```
kontena service scale nginx 2
```

Agora há duas instâncias do nginx rodando.

That's all!! Thanks!

# Considerações finais

## Problemas

Cuidado com DNS ou arquivo /etc/hosts (eu costumo colocar os ips ali e as vms também resolvem os nomes, mas os containers não), certifique-se que os containers conseguem resolver o nome dado ao master. Ou utilize ip fixo

**KONTENA_PEER_INTERFACE** é a interface utilizada para comunicação entre nós, como o linux pode mudar o nome dependendo do driver, e agora eth* não é garantido (eth0, enps160, wlansblabla666), certifique-se que ela está correta.

## Tips

Removendo todos os containers para reinstalar o kontena agent

```
kontena node rm node1 
ssh node1
docker stop $(docker ps -q) && docker rm $(docker ps -qa) && sudo reboot
```

Cuidado isso vai "zerar" todos os containers do nó.

Resetando o código master:

Logue-se na máquina master e execute:

```
docker exec -t kontena-server-api rake kontena:reset_admin
```

# Referências

http://www.kontena.io/docs/

https://coreos.com/os/docs/latest/booting-on-virtualbox.html

https://coreos.com/os/docs/latest/booting-on-vmware.html

https://coreos.com/os/docs/latest/cloud-config.html


