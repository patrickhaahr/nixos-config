{ ... }: {
  _module.args.hermesHonchoPlugin = {
    name = "honcho";
    configYaml = ''
      memory:
        provider: honcho
    '';
    honchoJson = {
      baseUrl = "http://api.honcho.svc.cluster.local";
      hosts.hermes = {
        enabled = true;
        aiPeer = "hermes";
        peerName = "ph";
        workspace = "hermes";
        apiKey = "__HERMES_HONCHO_API_KEY__";
        recallMode = "hybrid";
        writeFrequency = "async";
        sessionStrategy = "global";
        dialecticReasoningLevel = "low";
        dialecticDynamic = true;
      };
    };
  };
}
