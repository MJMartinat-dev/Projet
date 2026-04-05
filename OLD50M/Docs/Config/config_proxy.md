# Mode d'emploi : Paramétrer le fichier `.gitconfig` dans un dossier spécifique avec Git CMD et Git Bash

Ce guide explique comment paramétrer un fichier `.gitconfig` pour un projet Git situé dans un dossier spécifique, en utilisant **Git CMD** et **Git Bash**. Nous allons configurer Git pour un dépôt particulier en définissant des paramètres tels que le nom d'utilisateur, l'adresse e-mail, et le proxy. De plus, nous vérifierons si le dossier du projet existe, et s'il n'existe pas, nous allons le créer.

## Ouvrir le terminal Git

### Ouvrir Git Bash ou Git CMD

Avant de commencer, vous devez ouvrir **Git Bash** ou **Git CMD** :

- **Git Bash** : Ouvrez Git Bash à partir du menu Démarrer (Windows).
- **Git CMD** : Ouvrez Git CMD à partir du menu Démarrer (Windows).

## Se rendre dans le dossier du projet

Une fois le terminal ouvert, nous allons vérifier si le dossier existe. Si le dossier n'existe pas, nous allons le créer.

### Vérifier et créer le dossier

1. **Vérifier si le dossier existe** :
    Utilisez la commande suivante pour vérifier si le dossier existe déjà :

    ```bash
    if [ ! -d "/chemin/vers/votre/dossier" ]; then
        echo "Le dossier n'existe pas. Création en cours..."
        mkdir -p "/chemin/vers/votre/dossier"
    fi
    ```

    Remplacez `/chemin/vers/votre/dossier` par le chemin réel où vous souhaitez créer votre projet. Cette commande va vérifier si le dossier existe et, si ce n'est pas le cas, il le créera.

2. **Naviguer vers le dossier** :
    Ensuite, vous pouvez vous rendre dans le dossier du projet avec la commande `cd` :

    ```bash
    cd /chemin/vers/votre/dossier
    ```

    Exemple sous Windows :
    ```bash
    cd C:/Users/VotreNomUtilisateur/Desktop/mon-projet
    ```

## Configurer le fichier `.gitconfig` pour le dépôt spécifique

Git permet de configurer des paramètres au niveau global (pour tous les projets) ou au niveau local (pour un projet spécifique). Ici, nous allons configurer des paramètres au niveau local pour ce projet particulier.

### Configurer votre nom et votre e-mail

Pour définir votre nom d'utilisateur et votre adresse e-mail uniquement pour ce dépôt, exécutez les commandes suivantes dans **Git Bash** ou **Git CMD** :

1. **Configurer le nom d'utilisateur** :
    ```bash
    git config --global user.name "Votre Nom"
    ```

2. **Configurer l'adresse e-mail** :
    ```bash
    git config --global user.email "votre.email@exemple.com"
    ```

### Configurer un proxy (si nécessaire)

Si vous devez utiliser un proxy pour vous connecter à Internet, vous pouvez configurer un proxy spécifique pour ce dépôt. Voici comment le faire :

1. **Configurer un proxy HTTP pour ce dépôt** :
    ```bash
    git config --global https.proxy "http://adresse.proxy:port"
    ```

2. **Vérifier que le proxy est bien configuré** :
    ```bash
    git config --get https.proxy
    ```

### Configurer le dépôt GitLab

Si vous travaillez avec un dépôt GitLab, vous pouvez ajouter un provider pour les credentials afin de ne pas avoir à entrer vos identifiants à chaque interaction avec le dépôt.

1. **Configurer le provider pour les credentials GitLab** :
    ```bash
    git config --global credential."https://gitlab.com".provider "generic"
    ```

## Modifier manuellement le fichier `.gitconfig` (optionnel)

Si vous préférez, vous pouvez également ouvrir et modifier le fichier `.gitconfig` manuellement. Voici comment procéder :

1. **Ouvrir le fichier `.gitconfig` avec un éditeur de texte** :
    - Utilisez la commande suivante pour ouvrir le fichier avec **Notepad** :
      ```bash
      notepad ~/.gitconfig
      ```

2. **Ajouter ou modifier les sections nécessaires** :
    Exemple de fichier `.gitconfig` :

    ```ini
    [user]
        name = "Votre Nom"
        email = "votre.email@exemple.com"

    [https]
        proxy = http://adresse.proxy:port

    [credential "https://gitlab.com"]
        provider = generic
    ```

3. **Enregistrer et fermer l'éditeur**.

## Vérifier la configuration

Pour vérifier que la configuration a bien été appliquée, vous pouvez utiliser les commandes suivantes dans **Git Bash** ou **Git CMD** :

- **Vérifier votre nom d'utilisateur** :
    ```bash
    git config --get user.name
    ```

- **Vérifier votre e-mail** :
    ```bash
    git config --get user.email
    ```

- **Vérifier le proxy** :
    ```bash
    git config --get https.proxy
    ```

## Conclusion

Vous avez maintenant configuré votre fichier `.gitconfig` pour un projet spécifique en utilisant **Git CMD** ou **Git Bash**. Vous pouvez également l'éditer manuellement à l'aide d'un éditeur de texte. Assurez-vous de bien vérifier la configuration pour éviter tout problème lors de l'interaction avec votre dépôt GitLab ou d'autres dépôts Git.

Si vous avez des questions ou des difficultés, n'hésitez pas à demander de l'aide !
