

# exemplo de request para estrutura de usuário
``` js
<script>
  async function loadCurrentUserData() {
    // 1) Usuário autenticado
    const { data: { user }, error: userErr } = await supabase.auth.getUser();
    if (userErr) throw userErr;
    if (!user) return null;

    const userName =
      user.user_metadata?.full_name ??
      user.user_metadata?.name ??
      user.email ??
      "Sem nome";

    // 2) Profile
    const { data: profile, error: profileErr } = await supabase
      .from("profiles")
      .select("user_id, stripe_customer_id, plan")
      .eq("user_id", user.id)
      .single();

    if (profileErr) throw profileErr;

    // 3) Subscription (ativa ou mais recente)
    const { data: subscription, error: subErr } = await supabase
      .from("subscriptions")
      .select(`
        id,
        status,
        current_period_start,
        current_period_end,
        cancel_at_period_end
      `)
      .eq("user_id", user.id)
      .in("status", ["active", "trialing"])
      .order("current_period_end", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (subErr) throw subErr;

    // 4) Folders + Prompts
    const { data: folders, error: foldersErr } = await supabase
      .from("folders")
      .select(`
        id,
        name,
        created_at,
        updated_at,
        prompts (
          id,
          name,
          content,
          created_at,
          updated_at
        )
      `)
      .eq("user_id", user.id)
      .order("created_at", { ascending: true });

    if (foldersErr) throw foldersErr;

    // 5) Estado final
    return {
      user: {
        id: user.id,
        name: userName
      },
      profile: {
        stripe_customer_id: profile?.stripe_customer_id ?? null,
        plan: profile?.plan ?? "free"
      },
      subscription: subscription
        ? {
            id: subscription.id,
            status: subscription.status,
            period_start: subscription.current_period_start,
            period_end: subscription.current_period_end,
            cancel_at_period_end: subscription.cancel_at_period_end
          }
        : null,
      folders: (folders ?? []).map(f => ({
        ...f,
        prompts: f.prompts ?? []
      }))
    };
  }
</script>

```


# formato da resposta
```json
{
  user: {
    id: string
    name: string
  },
  profile: {
    stripe_customer_id: string | null
    plan: 'free' | 'premium'
  },
  subscription: {
    id: string
    status: string
    period_start: string | null
    period_end: string | null
    cancel_at_period_end: boolean
  } | null,
  folders: Array<{
    id: string
    name: string
    created_at: string
    updated_at: string
    prompts: Array<{
      id: string
      name: string
      content: string
      created_at: string
      updated_at: string
    }>
  }>
}

```