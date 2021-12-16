FROM ubuntu:latest

# xdg base directory
ENV HOME=/home/dev
ENV XDG_CACHE_HOME=$HOME/.cache \
  XDG_CONFIG_DIRS=$HOME/etc/xdg \
  XDG_CONFIG_HOME=$HOME/.config \
  XDG_DATA_DIRS=/usr/local/share:/usr/share \
  XDG_DATA_HOME=$HOME/.local/share

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=14.15.1

RUN set -x \
  && : "Set locale" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    locales \
    locales-all \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
ENV LC_ALL=en_US.UTF-8 \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en

RUN set -x \
  && : "Install basic tools" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget \
    fzf \
    xclip \
    tmux \
    ssh \
    gnupg2 \
    sudo \
  && : "Clean" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && : "Install python" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
  && : "Ignore pip upgrade warning" \
  && pip3 install --no-cache setuptools \
  && : "Clean" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && cd /usr/local/bin \
  && ln -s /usr/bin/python3 python \
  && pip3 install --upgrade pip \
  && mkdir -p $HOME && cd


# install nodejs
RUN set -x \
  && : "Install node.js" \
  && apt-get update \
  && apt install -y --allow-downgrades libssl1.1=1.1.1f-1ubuntu2 \
  && apt install -y npm \
  && curl -sL https://deb.nodesource.com/setup_15.x | sudo -E bash -

#RUN apt-get -y install nodejs npm
#RUN npm install


# install yarn
RUN set -x \
  && apt-get update \
   #&& curl -fsSL --no-check-certificate https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && wget -q -O - /tmp/pubkey.gpg https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get -y --no-install-recommends install yarn \
  && : "Clean" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && : "Install ruby" \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    gcc \
    make \
    ruby \
    ruby-dev \
  && : "Clean" \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && : "Install ripgrep" \
  && RIPGREP_VERSION=11.0.2 \
  && RIPGREP_DEB=ripgrep_${RIPGREP_VERSION}_amd64.deb \
  && RIPGREP_URL=https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_DEB} \
  && curl -LO $RIPGREP_URL \
  && dpkg -i $RIPGREP_DEB \
  && rm $RIPGREP_DEB

RUN set -x \
  && : "Install neovim" \
  && wget -q https://github.com/neovim/neovim/releases/download/v0.4.4/nvim.appimage \
  && chmod u+x ./nvim.appimage \
  && ./nvim.appimage --appimage-extract \
  && mv ./squashfs-root /opt/nvim \
  && chmod -R +rx /opt/nvim \
  && ln -s /opt/nvim/usr/bin/nvim /usr/local/bin/nvim \
  && : "Install nvim tool" \
  && pip3 install --no-cache pynvim \
                pynvim \
                neovim \
  && curl -fLo "${XDG_DATA_HOME}/nvim/site/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
  #&& npm install -g neovim \
  #&& gem install neovim \
  && : "Clean" \
  && rm nvim.appimage

RUN set -x \
  && : "Git clone the .vim files" \
  && git clone https://github.com/sktrinh12/dot_files.git $HOME/dot_files

# copy config files and tmux files; init bare git repo
RUN set -x \
  && : "git dotfiles" \
  && mkdir -p $HOME/.config/ \
  && cp -r $HOME/dot_files/.config/* $HOME/.config/ \
  && cp $HOME/dot_files/.tmux.conf $HOME/ \
  && git init --bare $HOME/.config \
  && echo "alias dotfiles='/usr/bin/git --git-dir=${HOME}/.config/ --work-tree=${HOME}'" >> ~/.bashrc

RUN set -x \
  && : "search and replace in dotfiles content" \
  && sed -i "s|let g:python3_host_prog = '~/miniconda3/envs/py37/bin/python3.7'||g" $HOME/.config/nvim/general.vim \
  && sed -i "s|set shell=/usr/local/bin/zsh||g" $HOME/.config/nvim/general.vim \
  && sed -i "s|/usr/local/bin/zsh|/usr/bin/bash|g" $HOME/.tmux.conf \
  && sed -i "s|/bin/sh|/usr/bin/bash|g" $HOME/.tmux.conf \
  && sed -i "s|Plug '/usr/local/opt/fzf'|Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }|g" $HOME/.config/nvim/plugin_list.vim

RUN set -x \
  && : "Create xdg base direcotry" \
  && mkdir -p $XDG_CACHE_HOME \
  && mkdir -p $XDG_DATA_HOME \
  && : "Setting for normal user" \
  && chmod -R 777 $XDG_CACHE_HOME $XDG_CONFIG_HOME $XDG_DATA_HOME \
  && : "Install nvim plugins" \
  && nvim +PlugInstall +qa \
  && nvim +UpdateRemotePlugins +qa \
  && nvim +CocInstall coc-python +qa \
  && nvim +CocInstall coc-tsserver coc-json coc-html coc-css +qa

RUN set -x \
  && : "Create home directory for all user" \
  && chmod -R 777 $HOME

RUN set -x \
  && echo "alias python=python3" >> ~/.bashrc \
  && bash -c 'source ~/.bashrc'

ENV SOURCE_DIR=/workspace
ENV TERM=xterm-256color
ENV VIRTUAL_ENV=/workspace/Documents/ubuntu/venv_general/venv

# for VENV
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y python3-venv

RUN python3 -m venv $VIRTUAL_ENV
ENV PATH "${VIRTUAL_ENV}/bin:${PATH}"
RUN pip install numpy pandas matplotlib scipy wheel fastapi Jinja2 aiofiles python-multipart

RUN set -x \
  && : "Create workspace for all user" \
  && mkdir -p $SOURCE_DIR \
  && chmod 777 $SOURCE_DIR \
  && echo "alias venv='source ${VIRTUAL_ENV}/bin/activate'" >> $HOME/.bashrc \
  && echo "alias ..='cd ..'" >> $HOME/.bashrc


COPY dotfile_alias.sh .

WORKDIR $SOURCE_DIR

VOLUME "${SOURCE_DIR}"

ENV DEBIAN_FRONTEND=dialog \
    SHELL=/bin/bash

RUN git config --global user.name "sktrinh12" && git config --global user.email sktrinh12@gmail.com

RUN chmod +x /dotfile_alias.sh

#ENTRYPOINT ["/dotfile_alias.sh"]
EXPOSE 1338 

CMD ["/bin/bash"]
