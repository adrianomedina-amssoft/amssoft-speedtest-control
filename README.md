# AMS SpeedTest Control

Painel centralizado para instalar, acompanhar e administrar os principais
medidores de velocidade do seu provedor.

Tenha uma visão clara da operação, identifique falhas com rapidez e execute as
ações do dia a dia em uma única interface, com menos dependência de comandos no
terminal.

## Tudo o que você precisa em um único painel

- acompanhe em tempo real a situação dos medidores e serviços;
- visualize CPU, memória, rede, tráfego, disponibilidade e saúde do servidor;
- inicie, pare, reinicie e verifique serviços com ações protegidas;
- instale, repare ou remova medidores por um fluxo guiado;
- consulte alertas, logs, diagnósticos e histórico de operações;
- administre bloqueios de IP e acompanhe as ações realizadas;
- personalize o nome do provedor e o domínio do SpeedTest;
- configure o certificado SSL e acompanhe sua renovação automática;
- gerencie a licença da instalação diretamente pelo painel.

## Medidores integrados

- Ookla;
- Minha Conexão;
- nPerf;
- medidor local AMS SOFT.

## Tecnologias e serviços de terceiros

O AMS SpeedTest Control é uma solução independente de gerenciamento, automação
e observabilidade. A licença comercial da AMS SOFT cobre exclusivamente o
painel, seus recursos de gestão, métricas, segurança, atualizações e suporte.

Ookla, Speedtest, Minha Conexão e nPerf são produtos, serviços ou marcas
pertencentes aos seus respectivos titulares. A AMS SOFT não vende, sublicencia
nem reivindica propriedade sobre esses componentes. Quando solicitada pelo
cliente, a plataforma apenas automatiza a obtenção, instalação, configuração e
supervisão dos componentes disponibilizados por suas fontes oficiais, sempre
sujeitos aos termos, requisitos e autorizações de cada fornecedor.

O medidor local incorpora componentes do projeto LibreSpeed, distribuídos sob a
licença GNU LGPLv3. Os avisos de autoria e a licença correspondente são
preservados junto ao componente.

A AMS SOFT não possui vínculo, patrocínio ou endosso dos titulares mencionados,
salvo quando formalmente informado.

## Benefícios para o provedor

- operação centralizada e mais simples;
- diagnóstico mais rápido de indisponibilidades;
- redução de tarefas manuais no servidor;
- maior controle sobre serviços, acesso e alterações;
- visão consolidada das métricas importantes do ambiente.

## Instalação

Para baixar e instalar o AMS SpeedTest Control, execute:

```bash
curl -fsSL https://github.com/adrianomedina-amssoft/amssoft-speedtest-control/releases/latest/download/install.sh | sudo bash
```

### Atualização de instalações antigas

Para a primeira atualização de uma instalação até a versão 1.0.11,
para a versão 1.0.12 ou posterior, execute novamente o comando de instalação acima por SSH. O instalador novo
identifica o sistema existente, verifica a assinatura da release com a chave
já instalada e usa uma migração protegida com recuperação automática. Ele
preserva as configurações e o banco; não executa uma instalação limpa nem
substitui a chave de confiança. Se a chave instalada não corresponder à da
release, interrompa a operação e contate o suporte.

O botão **Atualizar** de uma versão antiga continua executando o agente antigo
e não recebe retroativamente a migração de DNS nem seu rollback. Depois da migração protegida, as
atualizações seguintes podem ser feitas pelo painel. Este procedimento passa
a valer quando uma release que o inclua for publicada; o código local em
desenvolvimento ainda não é uma atualização oficial.

## Requisitos

- VM ou servidor com Debian 12 `amd64`;
- acesso `root` ou `sudo` para a instalação;
- conexão HTTPS com o GitHub e com o serviço de licenciamento;
- licença comercial válida para liberar as operações e os medidores.

A partir da versão 1.0.12, instalação e migração pelo instalador configuram
DNS públicos `1.1.1.1` e `8.8.8.8`, com backup do estado anterior. Estes
resolvedores precisam estar acessíveis por UDP/TCP 53. Redes que dependem de
zonas DNS privadas devem avaliar essa política antes de instalar ou atualizar.
O download inicial ainda depende de o DNS existente resolver o GitHub.

## Primeiro acesso

Depois da instalação, o painel poderá ser aberto pelo endereço IP da VM. O
cliente poderá conhecer a interface e informar sua licença antes de liberar as
operações. Nome do provedor, domínio e email técnico serão configurados no
próprio painel.

## Licenciamento

O AMS SpeedTest Control é um software comercial proprietário. Cada instalação
exige uma licença válida vinculada à assinatura contratada. A disponibilidade
pública dos arquivos de instalação não transforma o produto em software de
código aberto.

## Suporte e segurança

Para atendimento comercial ou suporte, utilize os canais oficiais da AMS SOFT.
Não publique vulnerabilidades, credenciais, chaves de licença, bancos ou logs
completos em issues públicas. Consulte a [Política de Segurança](SECURITY.md).
