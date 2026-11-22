_: {
  flake.modules.nixos.homelab-searxng =
    { config, ... }:
    let
      domain = "searxng.${config.homelab.domain}";
      disabled = map (name: {
        inherit name;
        disabled = true;
      });
      enabled = map (name: {
        inherit name;
        disabled = false;
      });
    in
    {
      sops.secrets.searxng_secret = { };
      sops.templates."searxng.env".content = ''
        SEARXNG_SECRET=${config.sops.placeholder.searxng_secret}
      '';

      services.searx = {
        enable = true;
        inherit domain;
        configureNginx = true;

        uwsgiConfig = { };
        environmentFile = config.sops.templates."searxng.env".path;
        settings = {
          server = {
            secret_key = "$SEARXNG_SECRET";
            image_proxy = true;
            method = "GET";
          };
          search = {
            default_lang = "da-DK";
            formats = [
              "html"
              "json"
              "csv"
              "rss"
            ];
          };
          ui = {
            default_locale = "en";
            theme_args.simple_style = "dark";
            hotkeys = "vim";
          };
          doi_resolvers = {
            "oadoi.org" = "https://oadoi.org/";
            "doi.org" = "https://doi.org/";
            "sci-hub.se" = "https://sci-hub.se/";
            "sci-hub.st" = "https://sci-hub.st/";
            "sci-hub.ru" = "https://sci-hub.ru/";
          };
          default_doi_resolver = "oadoi.org";
          engines =
            disabled [
              "artic"
              "arxiv"
              "bing images"
              "bing news"
              "bing videos"
              "openverse"
              "chefkoch"
              "currency"
              "deviantart"
              "devicons"
              "docker hub"
              "etymonline"
              "flickr"
              "gentoo"
              "hoogle"
              "kickass"
              "lemmy communities"
              "lemmy users"
              "lemmy posts"
              "lemmy comments"
              "lingva"
              "lucide"
              "mastodon users"
              "mastodon hashtags"
              "mdn"
              "mixcloud"
              "mankier"
              "openairedatasets"
              "openairepublications"
              "pdbe"
              "pexels"
              "piratebay"
              "pypi"
              "radio browser"
              "reuters"
              "sepiasearch"
              "askubuntu"
              "semantic scholar"
              "startpage"
              "startpage news"
              "startpage images"
              "solidtorrents"
              "unsplash"
              "dailymotion"
              "vimeo"
              "wikinews"
              "wikicommons.images"
              "wikicommons.videos"
              "wikicommons.audio"
              "dictzone"
              "mymemory translated"
              "wordnik"
              "tootfinder"
              "wttr.in"
              "bt4g"
            ]
            ++ enabled [
              "goodreads"
              "hackernews"
              "nyaa"
              "tmdb"
            ]
            ++ [
              {
                name = "nixos wiki";
                engine = "mediawiki";
                shortcut = "nixw";
                base_url = "https://wiki.nixos.org/";
                search_type = "text";
                disabled = false;
                categories = [
                  "it"
                  "software wikis"
                ];
              }
            ];
        };
      };
    };
}
