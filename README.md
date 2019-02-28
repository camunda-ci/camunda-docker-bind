# camunda-bind

Docker image for Bind.

## Additional Packages

  - bind9

## Ports

- `53/udp` dns
- `53` dns over tcp
- `8053` bind statistics as xml

## Usage

```bash
make daemon
```

## Build and test bind

```bash
make build
```

