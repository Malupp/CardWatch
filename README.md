# CardWatch

CardWatch is a Flutter application that allows you to browse trading cards and keep track of price drops.

## Getting Started

1. Install Flutter and run `flutter pub get`.
2. Create a `.env` file in the project root with the following variables:
   ```
   BASE_SCRYFALL_API=https://api.scryfall.com
   BASE_MARKETPLACE_API=<your marketplace api>
   MARKETPLACE_TOKEN=<token>
   ```
3. Launch the app with `flutter run`.

The app periodically checks the marketplace for lower prices and shows local notifications when a better offer is found.

