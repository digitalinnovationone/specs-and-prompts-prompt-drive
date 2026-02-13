// Supabase Edge Function: Stripe webhook
// Handles checkout.session.completed, customer.subscription.updated, customer.subscription.deleted

import Stripe from "https://esm.sh/stripe@14?target=denonext";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {});
const cryptoProvider = Stripe.createSubtleCryptoProvider();

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  const signature = req.headers.get("Stripe-Signature");
  if (!signature || !webhookSecret) {
    return new Response(JSON.stringify({ error: "Missing signature or secret" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const body = await req.text();
  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret,
      undefined,
      cryptoProvider
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.client_reference_id;
        if (!userId) {
          console.warn("checkout.session.completed: missing client_reference_id");
          break;
        }

        const customerId = typeof session.customer === "string" ? session.customer : session.customer?.id ?? null;
        await supabase
          .from("profiles")
          .update({
            plan: "premium",
            ...(customerId && { stripe_customer_id: customerId }),
            updated_at: new Date().toISOString(),
          })
          .eq("user_id", userId);

        const subscriptionId = typeof session.subscription === "string" ? session.subscription : session.subscription?.id;
        if (subscriptionId) {
          const subscription = await stripe.subscriptions.retrieve(subscriptionId);
          const item = subscription.items.data[0];
          const price = item?.price;

          await supabase.from("subscriptions").upsert(
            {
              user_id: userId,
              stripe_subscription_id: subscription.id,
              stripe_customer_id: subscription.customer as string,
              status: subscription.status,
              price_id: price?.id ?? null,
              product_id: price?.product as string ?? null,
              currency: price?.currency ?? null,
              interval: price?.recurring?.interval ?? null,
              interval_count: price?.recurring?.interval_count ?? null,
              current_period_start: subscription.current_period_start
                ? new Date(subscription.current_period_start * 1000).toISOString()
                : null,
              current_period_end: subscription.current_period_end
                ? new Date(subscription.current_period_end * 1000).toISOString()
                : null,
              cancel_at_period_end: subscription.cancel_at_period_end ?? false,
              canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
              ended_at: null,
              updated_at: new Date().toISOString(),
            },
            { onConflict: "stripe_subscription_id" }
          );
        }
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const item = subscription.items.data[0];
        const price = item?.price;

        const { data: row } = await supabase
          .from("subscriptions")
          .select("user_id")
          .eq("stripe_subscription_id", subscription.id)
          .single();

        if (row) {
          await supabase
            .from("subscriptions")
            .update({
              status: subscription.status,
              current_period_start: subscription.current_period_start
                ? new Date(subscription.current_period_start * 1000).toISOString()
                : null,
              current_period_end: subscription.current_period_end
                ? new Date(subscription.current_period_end * 1000).toISOString()
                : null,
              cancel_at_period_end: subscription.cancel_at_period_end ?? false,
              canceled_at: subscription.canceled_at ? new Date(subscription.canceled_at * 1000).toISOString() : null,
              updated_at: new Date().toISOString(),
            })
            .eq("stripe_subscription_id", subscription.id);

          const isActive = subscription.status === "active" || subscription.status === "trialing";
          if (!isActive) {
            await supabase
              .from("profiles")
              .update({ plan: "free", updated_at: new Date().toISOString() })
              .eq("user_id", row.user_id);
          }
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const { data: row } = await supabase
          .from("subscriptions")
          .select("user_id")
          .eq("stripe_subscription_id", subscription.id)
          .single();

        if (row) {
          await supabase
            .from("subscriptions")
            .update({
              status: subscription.status,
              ended_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .eq("stripe_subscription_id", subscription.id);

          await supabase
            .from("profiles")
            .update({ plan: "free", updated_at: new Date().toISOString() })
            .eq("user_id", row.user_id);
        }
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }
  } catch (err) {
    console.error("Webhook handler error:", err);
    return new Response(JSON.stringify({ error: "Internal error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
