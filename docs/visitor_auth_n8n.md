# Visitantes com Supabase + n8n

## Fluxo recomendado

1. O admin dispara um workflow no n8n com nome, email e telefone do visitante.
2. O n8n gera uma senha temporaria segura.
3. O n8n cria o usuario no Supabase Auth usando a Service Role Key.
4. O trigger `handle_new_user` cria o perfil em `profiles` com `role = viewer`.
5. O n8n envia um email com:
   - URL do app
   - email de login
   - senha temporaria
   - orientacao para trocar a senha pelo link "Esqueci minha senha"

## Supabase Auth Admin API

Metodo:

```text
POST https://SEU_PROJECT_REF.supabase.co/auth/v1/admin/users
```

Headers:

```text
apikey: SUPABASE_SERVICE_ROLE_KEY
Authorization: Bearer SUPABASE_SERVICE_ROLE_KEY
Content-Type: application/json
```

Body:

```json
{
  "email": "visitante@email.com",
  "password": "SENHA_TEMPORARIA",
  "email_confirm": true,
  "user_metadata": {
    "full_name": "Nome do Visitante",
    "phone": "61999999999",
    "profile_type": "visitor",
    "role": "viewer"
  }
}
```

## Email sugerido

Assunto:

```text
Acesso ao HandBrasil Stats
```

Corpo:

```text
Ola, {{nome}}.

Seu acesso ao HandBrasil Stats foi criado.

Link: https://handbrasilstats.vercel.app
Login: {{email}}
Senha temporaria: {{senha_temporaria}}

Por seguranca, recomendamos trocar a senha no primeiro acesso usando a opcao "Esqueci minha senha".
```

## Configuracao obrigatoria no Supabase

Em Authentication > URL Configuration:

```text
Site URL: https://handbrasilstats.vercel.app
Redirect URLs:
https://handbrasilstats.vercel.app/reset-password
http://localhost:*/reset-password
```

## Observacao de seguranca

Enviar senha por email funciona para uma senha temporaria, mas nao e o ideal para senha definitiva. O fluxo mais seguro e enviar um link de convite/redefinicao para a pessoa criar a propria senha.
