## Run Confluence in dev mode

This directory helps running a dev version of Confluence.

Several versions can run in parallel, thanks to the magic of ports.

## How to start

Run `build-images.sh` to build all most important images. You can also build individual images
with `build-image.sh`, using examples from the former script.

It creates a directory for each version + a docker-compose.yml file.
Go to that directory and run `docker-compose up` and magic will happen.
The .jar files of plugins to install can go to the `quickreload` directory.

## Big tips

The cookies overlap each other when http://localhost:[port] is opened on several ports.
Edit your [/etc/hosts](/etc/hosts) to add more domains, such as:

```
127.0.0.1 c7.19.0.local c8.5.0.local c8.8.0.local c8.9.0.local
```
