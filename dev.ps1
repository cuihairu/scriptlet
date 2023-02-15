scoop 
if (!$?) {
    Set-ExecutionPolicy RemoteSigned -scope CurrentUser
    iwr -useb get.scoop.sh | iex
}
scoop bucket add java
scoop bucket add extras
scoop update
scoop install 7zip sudo git maven idea vscode curl wget nodejs-lts gow python typora postman vim neovim dbeaver windows-terminal
scoop install openjdk8-redhat mobaxterm anaconda3 apache autohotkey baretail cacert dark fzf vifm wget yarn
scoop install go helm innounp kubectl lessmsi lxrunoffline mariadb minikube pandoc redis serverless tldr z
