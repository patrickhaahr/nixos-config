_: {
  flake.modules.nixos.locale-dk = {
    time.timeZone = "Europe/Copenhagen";
    i18n.defaultLocale = "en_DK.UTF-8";
    console.keyMap = "dk-latin1";
    services.xserver.xkb.layout = "dk";
  };
}
