{
  description = "Personal templates";

  outputs = { self }: {
    templates = {
      default = {
        path = ./default;
        description = "Default template";
      };
      wsl = {
        path = ./wsl;
        description = "NixOS configuration for WSL";
      };
    };
  };
}
