# WeatherOS Google Play support products

Owner: **OnlyTruePerspective LLC**  
Android package: `app.weatheros.app`

WeatherOS uses two clearly separated product groups:

1. Permanent feature unlocks are non-consumable one-time products. A higher
   tier includes the app entitlements of every lower tier.
2. Optional repeat tips are consumable one-time products. They grant no
   additional entitlement and can be purchased again.

There are no subscriptions.

## Permanent unlock catalog

| Product ID | Play title | Default US price | Delivered entitlement |
| --- | --- | ---: | --- |
| `weatheros_coffee_unlock` | Coffee — Permanent WeatherOS Unlock | $1.99 | Atmosphere personalization and supporter insignia |
| `weatheros_supercharge_unlock` | Supercharge — Permanent WeatherOS Unlock | $4.99 | Coffee tier plus advanced forecast tooling |
| `weatheros_patron_unlock` | Patron — Permanent WeatherOS Unlock | $9.99 | Every unlock plus WeatherOS Labs |

Use a **buy** purchase option and do not mark these products consumable.

## Optional repeat-tip catalog

| Product ID | Play title | Default US price | Behavior |
| --- | --- | ---: | --- |
| `weatheros_coffee_tip` | Coffee Tip for WeatherOS | $1.99 | Optional, repeatable contribution |
| `weatheros_supercharge_tip` | Supercharge Tip for WeatherOS | $4.99 | Optional, repeatable contribution |
| `weatheros_patron_tip` | Patron Tip for WeatherOS | $9.99 | Optional, repeatable contribution |

Use a **buy** purchase option. The app consumes these products after purchase
so they can be purchased again.

## Play Console ownership and activation

Create all six products inside the existing WeatherOS app in the
OnlyTruePerspective LLC Play Console developer account. Confirm the Payments
profile legal business name is OnlyTruePerspective LLC before activation.

Do not activate the permanent products until their listed features are in the
uploaded internal-test build. Test each product with a Play license tester from
an internal-testing install; sideloaded and web builds cannot exercise Play
Billing.

The app queries Google Play for localized prices and never treats the fallback
US display prices as the transaction price. Permanent ownership is restored
from Google Play and cached locally. For launch, purchase status is validated
through Play Billing on-device; server-side purchase-token verification can be
added later if the entitlement value or fraud risk grows.
