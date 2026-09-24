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

## Requisitos

- VM ou servidor com Debian 12 `amd64`;
- acesso `root` ou `sudo` para a instalação;
- conexão HTTPS com o GitHub e com o serviço de licenciamento;
- licença comercial válida para liberar as operações e os medidores.

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
