# Política do repositório de distribuição

Este repositório distribui binários proprietários assinados do AMS SpeedTest Control. O código-fonte permanece no repositório privado da AMS SOFT.

## Branch `main`

Somente são permitidos:

- metadados Git e workflow de verificação;
- documentação pública e licença;
- `install.sh`;
- `release-public.pem`, que contém apenas a chave pública usada para verificar releases.

Bundles, manifestos, assinaturas, atestações e changelogs versionados são publicados como ativos de GitHub Releases estáveis e imutáveis.

## Nunca permitido

Código-fonte, testes internos, `.env`, credenciais, chave privada, banco, log, backup, cookie, HAR, evidência de cliente, source map ou artefato de laboratório. A presença de qualquer arquivo fora da allowlist reprova a distribuição.

O `.gitignore` nega tudo por padrão, e o workflow confere a branch e todo o histórico. Se material sensível for exposto, ele deve ser revogado e removido do histórico; um commit posterior apagando o arquivo não é suficiente.
