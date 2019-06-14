# ULCC deployment of EPrints 3.3 branch #

ULCC EPrints deployment is based on https://github.com/eprints/eprints/tree/3.3 (which is currently the active development branch).

Contributors *must* use the following branching model: http://nvie.com/posts/a-successful-git-branching-model/

## Getting Started - Developers

Assuming your want to work in /opt/eprints3:

````
cd /opt
mkdir eprints3
chown eprints:eprints eprints3
chmod 02775 eprints3
cd eprints3
su eprints
git clone https://github.com/eprintsug/ulcc-core.git .
git checkout develop # the development branch
cp perl_lib/EPrints/SystemSettings.pm.ulcc perl_lib/EPrints/SystemSettings.pm
````

Edit SystemSettings.pm to suit - usually this just means adding the appropriate user and group.

````
git submodule init
git submodule update
````

To create a repository, first fork https://bitbucket.org/ulcc-art/ulcc-skel.git, then:

````
cd archives
git clone https://bitbucket.org/your/fork
````

The repository will only contain a minimal set of files which you can edit to suit:

````
 tree archives/foo
 archives/foo/
 ├── cfg
 │   ├── cfg.d
 │   │   ├── 10_core.pl # hostname of repository
 │   │   ├── adminemail.pl
 │   │   └── database.pl # db connection details (use 'bin/epadmin config_db foo' to change if preferred)
 │   └── lang
 │       └── en
 │           └── phrases
 │               └── archive_name.xml # repository name
 ├── documents
 ├── html
 └── var
````

Get everything up and running:

````
cd /opt/eprints3
mkdir archives/foo/documents/disk0
bin/epadmin create_db foo
bin/import_subjects foo lib/defaultcfg/subjects
bin/generate_apacheconf --replace --system # follow instructions for adding EPrints to global apache conf
bin/epadmin create_user foo
testdata/bin/import_test_data foo archive username
````

### Enabling plugins ###

In most cases, plugins can be enabled with 2 steps, for example:

````
tools/epm link_lib bootstrap
tools/epm enable foo bootstrap
````

Some plugins require additional steps - see below.

**RIOXX2 and Recollect**

Both of these expect to find a workflow file archives/foo/cfg/workflows/eprint/default.xml - the ulcc-skel repository does not provide this file so do the following before enabling:

````
mkdir -p archives/blank/cfg/workflows/eprint/
cp lib/defaultcfg/workflows/eprint/default.xml archives/blank/cfg/workflows/eprint/
````

**MePrints**

MePrints expects to find 2 workflow files: archives/foo/cfg/workflows/eprint/default.xml and archives/foo/cfg/workflows/user/default.xml - the ulcc-skel repository does not provide these files so do the following before enabling:

````
mkdir -p archives/blank/cfg/workflows/eprint/
mkdir -p archives/blank/cfg/workflows/user/
cp lib/defaultcfg/workflows/eprint/default.xml archives/blank/cfg/workflows/eprint/
cp lib/defaultcfg/workflows/user/default.xml archives/blank/cfg/workflows/user/
````
### Creating a release ###

(With reference to http://nvie.com/posts/a-successful-git-branching-model/)

First create release branch:

```
git checkout -b release-x.y.z develop # insert appropriate version
vim lib/syscfg.d/ulcc_version.pl # update version
git add lib/syscfg.d/ulcc_version.pl # etc.
git commit -m "Bump version to x.y.z"
# commit any other release-specific changes
git push origin release-x.y.z
```

When the release branch is ready to become a real release:

```
git checkout master
# make sure working copy is clean
git merge --no-ff release-x.y.z
git push origin master
git tag -a x.y.z
```

Finally merge the release-specific changes into develop:

```
git checkout develop
# make sure working copy is clean
git merge --no-ff release-x.y.z
git push origin develop
git branch -d release-x.y.z # delete local release branch
git push origin :release-x.y.z # delete remote release branch
```

### Adding new plugins ###

```
git checkout develop # don't modify the master branch
git submodule add http://github.com/eprintsug/foo lib/epm/foo
git status # should show changes to .gitmodules and lib/epm/foo
git commit -am "Added foo 1.0.0"
git push
```

### Update all submodules ###

```
$ git submodule foreach git pull origin master
```

### Migrating from EPrints Bazaar ###

Some plugins are not source controlled - in general it's a good idea to move these onto a platform like github so that changes can be tracked and contributions managed.

Firstly, make sure you are working on the develop branch and have clean working directories (/opt/eprints3 and /opt/eprints3/archives/foo).

Install the plugin in the normal way via the EPrints Bazaar screen in EPrints (under the Admin menu).

Next use git status to identify the files that were installed:

```
git checkout develop # don't modify the master branch
git status
On branch develop
Your branch is up-to-date with 'origin/develop'.

Untracked files:
  (use "git add <file>..." to include in what will be committed)

        lib/epm/orcid_tier_1_importer/
        lib/lang/en/phrases/orcid.xml
        lib/plugins/
        lib/static/images/epm/orcid_import_1.png
        lib/static/style/auto/orcidmanager.css

```

Make a note of the plugin ID - orcid_tier_1_importer in this case - and create a new repository (https://github.com/organizations/eprintsug/repositories/new) using the plugin ID as the repository name (don't add a README, .gitignore or license).

Now use the files installed by the plugin to layout the new repository:

```
cd /tmp
mkdir orcid_tier_1_importer
cd orcid_tier_1_importer
git init
cd /opt/eprints3
cp -r --parents lib/epm/orcid_tier_1_importer/ lib/lang/en/phrases/zz_check_doi.xml lib/plugins/ lib/static/images/epm/DoiCheckButton.png /tmp/orcid_tier_1_importer # all files/dirs reported by git status
cd /tmp/orcid_tier_1_importer
# change code layout
mv lib/epm/orcid_tier_1_importer/* .
rmdir lib/epm/orcid_tier_1_importer/
rmdir lib/epm
rm orcid_tier_1_importer.epm
tree
.
├── cfg
│   └── cfg.d
│       └── z_orcid.pl
├── lib
│   ├── lang
│   │   └── en
│   │       └── phrases
│   │           └── orcid.xml
│   ├── plugins
│   │   └── EPrints
│   │       └── Plugin
│   │           └── Screen
│   │               ├── Admin
│   │               │   └── Orcid
│   │               │       └── OrcidManager.pm
│   │               └── EPMC
│   │                   └── OrcidWorksTier1.pm
│   └── static
│       └── images
│           └── epm
│               └── orcid_import_1.png
└── orcid_tier_1_importer.epmi

```

Commit the code and push to github:
i
```
git add *
VERSION=$(xml_grep version orcid_tier_1_importer.epmi --text_only)
git commit -m "Add orcid_tier_1_importer $VERSION"
git remote add origin https://github.com/eprintsug/orcid_tier_1_importer.git
git push origin master
```

Finally clean up your working directories and you are ready to add the plugin using git submodule:

```
cd /opt/eprint3
git clean -xdf
git status # should report 'working directory clean'
cd archives/foo
git clean -xdf
git status # should report 'working directory clean'
```


## Merging upstream changes ##

ulcc-core is a fork of https://github.com/eprints/eprints/tree/3.3 so upstream changes can be merged as follows:

```
git clone git@github.com:eprintsug/ulcc-core .
git checkout develop # don't modify the master branch
git submodule init
git submodule update
git remote add upstream https://github.com/eprints/eprints.git
git fetch upstream 3.3
git merge upstream/3.3
# may need to fix conflicts and commit
git push
```

## Deployment - Staging / Production ##

Note: some older distros may not have the required SSL CAs for github, if you see an SSL certificate error prefix the git command with "env GIT_SSL_NO_VERIFY=true", for example:

```
env GIT_SSL_NO_VERIFY=true git clone https://github.com/eprintsug/ulcc-core.git .
```

Clone core and submodules:

```
cd /www/foo[-test]
mkdir eprints3
chown eprints:eprints eprints3
chmod 02775 eprints3
cd eprints3
su foo
git clone https://github.com/eprintsug/ulcc-core.git .
cp perl_lib/EPrints/SystemSettings.pm.ulcc perl_lib/EPrints/SystemSettings.pm
vim perl_lib/EPrints/SystemSettings.pm # set user and group
git submodule init
git submodule update
```

Use ssh-keygen to create a key pair and add the public key to the list of Deployment Keys for your bitbucket repository.

```
cd archives
git clone git@bitbucket.org:your/foo.git foo[test]
mkdir foo[test]/documents/disk0
```

Staging only:

```
cd cfg/cfg.d
cp 10_core.pl 10_core_test.pl # set staging hostname
cp database.pl database_test.pl # set staging db name, user and password
```

Install required EPMs:

```
cd /www/foo[-test]/eprints3
for epm in $(ls archives/foo[test]/cfg/epm); do tools/epm link_lib $epm; done
tools/epm link_lib meprints # if irstats enabled without meprints
```

Get up and running:

```
bin/epadmin create_db foo[test]
bin/generate_apacheconf
bin/epadmin foo[test] # final sanity check
# restart apache
```

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

## Docker image for ULCC Core

An docker image of ULCC Core is available in the Docker Hub https://hub.docker.com/r/researchtech/ulcc-core

The image contains an apache-based docker image containing the ulcc-core code, submodules and libraries and dependencies for running EPrints.

The current image is `alpha`

To try out the docker code locally:

* cp .env.template .env
* fill out the required variables in .env
* docker-compose up --build

You should see the apache 'it works' page running on port 80.

This image is intended to form the basis of a further Docker build for your application. 
