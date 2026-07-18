_: {
  _module.args.hermesHonchoPlugin = {
    name = "honcho";
    configYaml = ''
      memory:
        provider: honcho
    '';
    honchoJson = {
      baseUrl = "http://api.honcho.svc.cluster.local";
      base_url = "http://api.honcho.svc.cluster.local";
      hosts.hermes = {
        enabled = true;
        aiPeer = "hermes";
        peerName = "ph";
        workspace = "hermes";
        recallMode = "tools";
        writeFrequency = "async";
        sessionStrategy = "global";
        dialecticReasoningLevel = "low";
        dialecticDynamic = false;
      };
    };
  };
}
