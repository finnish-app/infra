{ pkgs, ... }: {
  imports = [];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "root";
  home.homeDirectory = "/root";

  home.stateVersion = "23.11"; # Please read the comment before changing.

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    userName = "Nicolas Auler";
    userEmail = "nickvarauler@gmail.com";

    extraConfig = {
      commit = {
        gpgsign = true;
      };
      gpg = {
        format = "ssh";
        ssh.allowedSignersfile = "/root/.ssh/allowed_signers";
      };
      user.signingkey = "/root/.ssh/id_ed25519.pub";

      core.editor = "nvim";
      init.defaultBranch = "main";
    };
  };
}
