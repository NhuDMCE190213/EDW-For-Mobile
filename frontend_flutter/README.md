# EDW Flutter frontend

The current Flutter screen is the staff product-variant management module. It
loads products and variants from the ASP.NET API and supports:

- filtering variants by product;
- creating and editing color, CPU, RAM, storage, screen size, price, stock,
  and image URL;
- deleting a variant;
- restocking an existing variant;
- stock status badges matching the old Razor staff screen.

## Running against the API

Start the API with the HTTP profile (`http://localhost:5238`) and run:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:5238
```

`10.0.2.2` is the host alias for an Android emulator. For Flutter Web or
Windows, use `http://localhost:5238` instead. The app defaults to the Android
emulator URL on mobile and localhost on web.
