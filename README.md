# ULCC deployment of EPrints 3.3 branch #

ULCC EPrints deployment is based on the eprintis:3.3 branch (which is currently the active development branch).

Contributors *must* use the following branching model: http://nvie.com/posts/a-successful-git-branching-model/

## Initial setup ##

````
git init
git remote add origin git@github.com:eprintsug/ulcc-core.git
git remote add upstream https://github.com/eprints/eprints.git
git remote -v # sanity check
git pull upstream 3.3
git push origin master
git branch --set-upstream-to=origin/master master
````
