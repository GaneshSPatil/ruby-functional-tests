#!/bin/bash

# 5, because that's the number of DBs we test are: h2, postgres(9.6, 10, 11 and 12)
db_mod="$((${GO_PIPELINE_COUNTER:-0} % 5))"

function use_jdk() {
    local jdk="openjdk@1.$1"

    if [ ! -f "${HOME}/.jabba/jabba.sh" ]; then
      curl -sL https://github.com/shyiko/jabba/raw/master/install.sh | bash
    fi
    source "${HOME}/.jabba/jabba.sh"

    jabba install "$jdk"
    jabba use "$jdk"
}


if  [[ "$(uname -s)" = Darwin* ]]; then
  echo "Running on Mac OS so using system Java, not modifying it. Please ensure a supported JDK is installed"

  JAVA_HOME="$(/usr/libexec/java_home)"
  # ensure java is resolvable; it hasn't always been for me (marques)
  # for some reason that I haven't figured out yet
  for wrapper in $(find . -type f -name wrapper.conf); do
    sed -i '' -e '/^wrapper\.java\.command=/d; /^set\.JAVA_HOME/d' "$wrapper"
    printf "wrapper.java.command=%s\nset.JAVA_HOME=%s\n" "$(command -v java)" "$JAVA_HOME" >> "$wrapper"
  done
else
  use_jdk "${BUILD_ON_JDK:-14}"
fi

echo "JAVA_HOME set to : $JAVA_HOME"

if [[ "$@" != *"restart"* ]]; then
  if [[ "$db_mod" = "0" ]]; then
      echo "Nothing to do here. Keep using h2."
  else
    echo "Copying db.properties to the config"
    cp db.properties config/

    dropdb --if-exists --host=localhost --port=5432 --username go cruise
    createdb --host=localhost --port=5432 --username go cruise
  fi
fi

exec "$@"
