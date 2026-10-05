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

## Histórico de versões descontinuadas

Os pacotes das versões abaixo foram retirados de distribuição. Utilize a [versão atual](https://github.com/adrianomedina-amssoft/amssoft-speedtest-control/releases/latest). Os changelogs são preservados abaixo para consulta.

### AMS SpeedTest Control 1.0.13

#### Primeiro acesso pelo navegador

- Instalações sem administrador permitem abrir o cadastro inicial mesmo quando o navegador chega por NAT e a instalação foi executada a partir de um painel na nuvem.
- Ao criar a senha, o sistema registra automaticamente a origem recebida pelo Apache como rede IPv4 /24 ou IPv6 /64 e encerra a abertura inicial.
- Redes administrativas existentes são preservadas. Instalações já configuradas mantêm suas restrições durante atualizações.
- Falhas ou interrupções após criar a senha são recuperadas automaticamente; o navegador consulta o progresso sem reenviar a senha.
- A confirmação do cadastro depende da aplicação da ACL e das verificações de saúde, evitando anunciar sucesso antes da autorização de acesso.

#### Instalação e atualização

O pacote continua nativo para Debian12 amd64, com serviços systemd, assinatura e verificação de integridade. O instalador oficial atende instalações novas e atualizações; este ajuste entra em vigor quando o novo agente estiver instalado e iniciado.

### AMS SpeedTest Control 1.0.12

#### Correções

- Instalações e atualizações pelo instalador assinado configuram DNS públicos genéricos `1.1.1.1` e `8.8.8.8`, sem depender de endereços privados de uma rede específica.
- O estado anterior de DNS é salvo e restaurado se a configuração ou a atualização falhar, incluindo o link original de `/etc/resolv.conf`.
- Atualizações executadas pelo agente novo incluem DNS no snapshot de recuperação após interrupção.
- O drop-in de `systemd-resolved` limpa as listas globais anteriores; o Cloud-Init recebe `manage_resolv_conf: false`. Rollback conserva também a configuração anterior de Cloud-Init e reinicia um resolvedor previamente ativo mesmo depois de falha no restart.

#### Primeira atualização de versões anteriores

Para instalações até a v1.0.11, execute o comando oficial de instalação por SSH para fazer a primeira migração protegida. O botão Atualizar do painel antigo usa seu agente instalado e não aplica retroativamente esta política DNS.

O download inicial exige resolução funcional do GitHub. Os DNS públicos precisam estar acessíveis na rede; a política não resolve zonas privadas. Configurar DNS não emite certificado e não comprova que A/AAAA apontam à VPS ou que ACME será aceito.

### AMS SpeedTest Control 1.0.11

#### Melhorias

- Acesso administrativo IPv6 inicial com orientação para restringir a rede após o primeiro acesso.
- Ajuda contextual discreta junto aos títulos dos cards.
- País, bandeira local e detalhes opcionais dos IPs nas telas de tráfego e sessões.
- Aba SMTP própria, com configuração e envio de teste separados.
- Confirmações e retornos de operações administrativas mais claros, sem etapas redundantes.
- Link para o histórico completo de versões na tela de atualização.

#### Correções

- Acompanhamento da instalação de SSL com marcos reais e recuperação após perda de conexão ou sessão.
- Disponibilidade dos recursos HTTP do nPerf em IPv4 e IPv6 sem redirecionamento indevido.
- Restauração do certificado público do Ookla após remover e reinstalar os medidores, com verificação da cadeia TLS servida e rollback que preserva permissões.
- Proteção Fail2ban alinhada ao log efetivo do Apache e espera pelo daemon na instalação limpa.
- Persistência e orientação das alterações de redes administrativas.
- Validação do email remetente e mensagens específicas nos formulários SMTP.
- Página padrão do Apache oculta antes da instalação do medidor local.
- Recuperação de atualização interrompida com snapshot obrigatório, restauração antes dos serviços no reboot e confirmação de saúde antes de encerrar o rollback.
- Migração inicial protegida para instalações legadas pelo instalador assinado; o botão de atualização de versões antigas não oferece esta proteção retroativamente.

Esta versão reúne as melhorias de operação, administração e medição validadas para o pacote assinado.

### AMS SpeedTest Control 1.0.9 (rascunho descontinuado)

Atualização de confiabilidade do licenciamento e da recuperação dos medidores.

#### Correções

- preserva a tolerância offline quando o servidor de licenças está
  temporariamente indisponível;
- mantém o bloqueio imediato para licenças realmente inválidas, suspensas,
  expiradas, revogadas ou clonadas;
- restaura os medidores com segurança depois da regularização da licença;
- impede que a falha isolada de um medidor bloqueie novamente toda a
  instalação.

#### Validação

- testes automatizados de licença, agente, guardião, firewall e serviços;
- verificação do adaptador contra o exemplo oficial instalado no WHMCS;
- recuperação controlada do piloto e conferência pelo painel e pelo host.

### AMS SpeedTest Control 1.0.8

Hotfix de segurança e confiabilidade para o servidor Ookla.

#### Correções

- restringe a política cross-domain do Ookla aos domínios necessários do
  ecossistema Speedtest;
- corrige automaticamente instalações anteriores durante o reparo;
- valida a política realmente publicada pelo servidor antes de considerar o
  medidor saudável;
- preserva os demais medidores, o perfil, o certificado e a licença durante a
  correção.

#### Validação

- atualização transacional com backup e rollback;
- testes automatizados do ciclo de instalação e reparo;
- upload e endpoints Ookla validados por HTTP e HTTPS;
- painel, banco e quatro medidores verificados após a atualização.

### AMS SpeedTest Control 1.0.7

Atualização voltada à segurança, confiabilidade da instalação e clareza das
operações administrativas.

#### Melhorias

- proteção adicional das conexões HTTPS depois da ativação do certificado
  público;
- reinstalações preservam e apresentam corretamente todas as Redes
  administrativas configuradas pelo cliente, inclusive IPv6;
- acesso direto a `/admin` funciona sem exigir que o operador memorize a barra
  final;
- respostas da API ficaram mais consistentes para clientes e ferramentas de
  monitoramento;
- tarefas, Perfil, licença e medidores mantêm estados mais claros depois de
  reinstalação e reinicialização.

#### Confiabilidade e segurança

- validação reforçada do pacote público e da automação de distribuição;
- licença, integridade, guardião e regras dos medidores foram retestados em uma
  VM Debian 12 limpa;
- os quatro medidores, domínio, SSL, renovação automática, IPv4 e IPv6 foram
  validados em conjunto antes da publicação.

### AMS SpeedTest Control 1.0.4

Atualização voltada à confiabilidade do painel, recuperação por atualização e
gestão do acesso administrativo.

#### Melhorias

- atualização oficial disponível pelo painel mesmo antes da ativação da
  licença, permitindo recuperar instalações desatualizadas;
- aviso de atualização reposicionado para permanecer visível durante a
  operação e reconexão automática após a aplicação;
- acesso direto à Área do Cliente da AMS SOFT pelo menu do painel;
- Redes administrativas com configuração IPv4 e IPv6 controlada pelo painel;
- formulários e mensagens de erro mais claros no modo demonstração.

#### Confiabilidade

- atualização executa migrações idempotentes antes de declarar o novo agente
  saudável;
- estado, histórico e versão instalada convergem após reload, sem oferecer
  downgrade;
- configuração administrativa existente é preservada durante atualização,
  reinstalação e reboot;
- publicação distribui somente os ativos operacionais e as provas de
  integridade necessárias.

### AMS SpeedTest Control 1.0.3

Atualização voltada ao controle seguro do acesso administrativo ao painel em
redes IPv4 e IPv6.

#### Melhorias

- nova área de Redes administrativas em Configurações, com visualização das
  faixas autorizadas e inclusão controlada de redes públicas ou IPv6;
- redes IPv4 privadas e CGNAT permanecem disponíveis por padrão, enquanto o
  acesso administrativo por IPv6 é habilitado somente quando configurado;
- alterações mostram o impacto antes da aplicação e preservam o acesso com
  confirmação e reversão automática;
- o modo demonstração mantém todas as opções de Administração visíveis em
  somente leitura, permitindo conhecer o painel antes da ativação;
- mensagens de validação orientam a correção de redes inválidas sem expor
  detalhes internos.

#### Confiabilidade

- configurações administrativas existentes são preservadas em reinstalações e
  atualizações;
- o agente local rejeita comandos inválidos sem interromper a comunicação com
  o painel;
- o acesso ao painel é separado das portas públicas dos medidores;
- validações de autenticação, integridade do Apache e recuperação automática
  protegem contra configurações que poderiam interromper o acesso.

### AMS SpeedTest Control 1.0.2

Atualização voltada a simplificar a configuração inicial e permitir que novas
versões estáveis sejam verificadas e aplicadas pelo próprio painel.

#### Melhorias

- nova área de atualização em Configurações, com consulta da versão estável,
  download, validação e aplicação protegida;
- instalação dos medidores e configuração de domínio/SSL organizadas em etapas
  separadas e mais claras;
- mensagens mais específicas quando uma operação é recusada ou precisa de ação
  no licenciamento;
- identificação correta entre primeira configuração de SSL e troca posterior de
  domínio;
- links dos medidores ajustados ao protocolo realmente disponível;
- histórico de atualização separado do estado operacional atual.

#### Confiabilidade

- atualizações validam autenticidade e integridade antes de modificar o sistema;
- falhas durante a atualização preservam o caminho de recuperação e rollback;
- inicialização após reboot respeita a validação de licença e integridade antes
  de liberar os medidores;
- nova versão permanece indisponível para instalação enquanto não concluir as
  verificações de publicação.

### AMS SpeedTest Control 1.0.1

Correção do fluxo de instalação pública para novas VMs Debian 12.

#### Melhorias

- inclui o `install.sh` entre os downloads obrigatórios da release estável;
- valida a assinatura do bootstrap diretamente com o OpenSSL local e a âncora pública fixada;
- autoriza a rede IPv4 `/24` ou IPv6 `/64` do operador SSH no primeiro acesso remoto quando ela não pertence às redes administrativas padrão;
- preserva a ACL existente nas reinstalações e mantém precedência para uma ACL informada explicitamente;
- amplia os testes permanentes do publicador, da assinatura e do primeiro acesso.
- rotaciona a âncora de assinatura antes da primeira instalação pública utilizável; a chave privada correspondente permanece fora dos repositórios e das VMs.

#### Segurança

O pacote continua sem código-fonte Go/React, source maps, credenciais, licença preenchida, dados pessoais, bancos ou chaves privadas de release. A chave privada do certificado bootstrap e a chave local de MFA são geradas na própria VM e permanecem `root:root 0600`.

### AMS SpeedTest Control 1.0.0

Gerencie seus servidores de teste de velocidade em um único painel, com visão
centralizada da operação, dos serviços e das principais métricas do ambiente.

#### O que você pode fazer

- acompanhar em tempo real o estado do Ookla, Minha Conexão, nPerf e medidor local;
- visualizar uso de CPU, memória, rede, tráfego, disponibilidade e saúde dos serviços;
- iniciar, parar, reiniciar e verificar os medidores diretamente pelo painel;
- instalar, reparar ou remover os medidores por um fluxo guiado, com progresso e histórico;
- consultar alertas, logs e diagnósticos para identificar problemas com mais rapidez;
- administrar bloqueios de IP e acompanhar as ações realizadas;
- personalizar o nome do provedor, domínio e dados técnicos do ambiente;
- configurar o certificado SSL e acompanhar sua renovação automática;
- gerenciar a licença da instalação em uma área simples e centralizada.

#### Benefícios

- menos dependência de comandos no terminal para as tarefas do dia a dia;
- identificação rápida de serviços parados, falhas e alterações no servidor;
- operação centralizada dos principais medidores de velocidade;
- mais segurança e rastreabilidade nas ações administrativas;
- experiência preparada para provedores que precisam manter seus medidores disponíveis e organizados.
