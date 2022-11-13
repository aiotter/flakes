{
  description = "Personal templates";

  outputs = { self }: {
    templates = {
      default = {
        path = ./default;
        description = "Default template";
      };
    };
  };
}
