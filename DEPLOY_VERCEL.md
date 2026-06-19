# Deploy no Vercel

Este projeto ja esta preparado para publicar a versao web no Vercel.

## 1. Antes de subir

Voce precisa ter:

- um repositorio no GitHub, GitLab ou Bitbucket com este projeto
- um projeto no Supabase funcionando
- os valores `SUPABASE_URL` e `SUPABASE_ANON_KEY`

Importante:

- no app web use somente a chave publica `anon`
- nunca use a `service_role` no frontend

## 2. Publicar no Git

Suba o projeto para o seu repositorio normalmente.

Se quiser conferir, o arquivo `.env` local nao deve ir para o Git. Use o `.env.example` como modelo.

## 3. Criar o projeto no Vercel

No painel do Vercel:

1. clique em `Add New Project`
2. importe o repositorio deste app
3. mantenha a raiz do projeto como a pasta principal
4. o Vercel vai ler o arquivo `vercel.json` automaticamente

## 4. Cadastrar as variaveis no Vercel

No projeto do Vercel, adicione estas variaveis em `Settings > Environment Variables`:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Essas variaveis serao injetadas no build web automaticamente.

## 5. Fazer o primeiro deploy

Depois de salvar as variaveis:

1. clique em `Deploy`
2. aguarde o build
3. abra a URL gerada pelo Vercel

## 6. Ajustar o Supabase

Se o cadastro com confirmacao de e-mail estiver ativo, ajuste no Supabase:

1. abra `Authentication > URL Configuration`
2. em `Site URL`, coloque a URL principal do Vercel
3. em `Redirect URLs`, adicione:
   - `http://localhost:3000/**`
   - `https://*-SEU-TIME-OU-USUARIO.vercel.app/**`
   - sua URL final de producao

Exemplo de producao:

- `https://handbrasil-stats-app.vercel.app`

## 7. Se usar dominio proprio

Depois de conectar o dominio no Vercel, atualize tambem no Supabase:

- `Site URL`
- `Redirect URLs`

## 8. Observacoes importantes

- o primeiro build no Vercel pode demorar mais porque o Flutter sera preparado no ambiente
- as rotas web ja foram configuradas para abrir corretamente mesmo ao atualizar a pagina
- o app agora aceita configuracao do Supabase por `.env` local e tambem por variaveis do deploy
