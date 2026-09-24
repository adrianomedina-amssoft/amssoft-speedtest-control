# AMS SpeedTest Control

Distribuicao binaria oficial do AMS SpeedTest Control para Debian 12 `amd64`.

O codigo-fonte, os testes internos e a infraestrutura de desenvolvimento nao fazem
parte deste repositorio. Os arquivos publicados aqui sao software comercial
proprietario e exigem uma licenca valida para liberar operacoes e medidores.

## Instalacao

Enquanto o dominio amigavel nao estiver ativado:

```bash
curl -fsSL https://raw.githubusercontent.com/adrianomedina-amssoft/amssoft-speedtest-control/main/install.sh | sudo bash
```

Endereco definitivo planejado:

```bash
curl -fsSL https://speedtest-control.amssoft.com.br | sudo bash
```

O instalador aceita somente releases estaveis no formato `X.Y.Z`, valida a
assinatura do bootstrap, a assinatura do manifesto e o SHA-256 do bundle antes de
alterar a VM.

## Requisitos

- Debian 12;
- arquitetura `amd64`;
- acesso root ou `sudo`;
- acesso HTTPS ao GitHub e a `license1.amssoft.com.br`.

## Suporte e seguranca

Nao envie vulnerabilidades em uma issue publica. Consulte [SECURITY.md](SECURITY.md).
Consulte tambem [DISTRIBUTION-POLICY.md](DISTRIBUTION-POLICY.md) para entender exatamente quais arquivos podem existir neste repositorio.
