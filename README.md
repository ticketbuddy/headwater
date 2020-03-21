# Headwater

Event source library.

```elixir
%Shop.CreateProduct{}
|> Shop.write() # OpFactory - builds the write request
|> MyRouter.handle() # Router - adds the config to the op for the application
|> Headwater.Directory.handle() # Directory - internal headwater processing.
```
