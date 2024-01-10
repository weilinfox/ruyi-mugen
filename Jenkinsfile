DISTROMAP = [
    'oE2309-x86_64': ['label': 'openEuler2309 && x86_64'],
    'oE2309-riscv64': ['label': 'openEuler2309 && riscv64'],
    'jammy-x86_64': ['label': 'jammy && x86_64'],
    'fedora38-x86_64': ['label': 'fedora38 && x86_64'],
    'revyos-riscv64': ['label': 'revyos && riscv64']
    ]

def mugen_install () {
    
    sh 'if curl -V > /dev/null; then curl -sLO https://gitee.com/weilinfox/mugen-ruyi/repository/archive/ruyisdk.tar.gz; fi'
    sh 'if [ ! -f "ruyisdk.tar.gz" ] && wget -V > /dev/null; then wget https://gitee.com/weilinfox/mugen-ruyi/repository/archive/ruyisdk.tar.gz; fi'
    
    // extract tarball
    sh """
    getdnf=\"\$(whereis -b dnf | cut -d':' -f2)\"
    getapt=\"\$(whereis -b apt-get | cut -d':' -f2)\"
    hastar=

    [ ! -z \"\$getdnf\" ] && dnf list --installed tar 2>&1 >/dev/null && hastar=y
    [ ! -z \"\$getapt\" ] && dpkg -l tar 2>&1 >/dev/null && hastar=y

    [ -z \"\$hastar\" ] && [ ! -z \"\$getdnf\" ] && dnf install -y tar
    [ -z \"\$hastar\" ] && [ ! -z \"\$getapt\" ] && apt-get update && apt-get install -y tar
    
    tar zxf ruyisdk.tar.gz && mv mugen-ruyi-ruyisdk mugen-ruyi
    
    if [ -z \"\$hastar\" ]; then
        [ ! -z \"\$getdnf\" ] && dnf remove -y tar
        [ ! -z \"\$getapt\" ] && apt-get remove -y tar && apt-get autoremove
    fi
    
    exit 0
    """

    sh 'cd mugen-ruyi && bash dep_install.sh'
    
    sh 'mkdir mugen-ruyi/conf'
    sh '''
    echo '{ "NODE": [{ "ID": 1, \
    "LOCALTION": "local", \
    "MACHINE": "physical", \
    "IPV6": "::1", \
    "FRAME": "", \
    "NIC": "", \
    "MAC": "", \
    "IPV4": "127.0.0.1", \
    "USER": "", \
    "PASSWORD": "", \
    "SSH_PORT": 22, \
    "BMC_IP": "", \
    "BMC_USER": "", \
    "BMC_PASSWORD": "" }]}' >> mugen-ruyi/conf/env.json
    '''
}

def mugen_run () {
    sh 'cd mugen-ruyi && bash mugen.sh -f ruyi -x || echo Mugen test failed'
    
    sh 'dnf install -y tar || apt-get install -y tar'

    sh 'for f in $(find ./mugen-ruyi/logs -type f); do mv "$f" "$(echo "$f" | sed "s/:/_/g")"; done'
    sh "tar zcvf ruyi-test-logs.tar.gz mugen-ruyi/logs"

    // get failed logs
    sh 'mkdir ./mugen-ruyi/logs_failed'
    sh '''
    for f in $(find ./mugen-ruyi/logs -type f); do
        if grep " - ERROR - failed to execute the case." "$f"; then
            NEW_FILE="$(echo "$f" | sed "s/logs/logs_failed/")"
            mkdir -p "$(dirname $NEW_FILE)"
            mv "$f" "$NEW_FILE"
        fi
    done
    rmdir --ignore-fail-on-non-empty ./mugen-ruyi/logs_failed
    '''
    sh "[ -d ./mugen-ruyi/logs_failed ] && tar zcvf ruyi-test-logs_failed.tar.gz mugen-ruyi/logs_failed || touch ruyi-test-logs_failed.tar.gz"
}

pipeline {
    agent none

    options {
        timeout(time: 5, unit: 'HOURS')
    }

    stages {
        stage('ruyi-test') {
            matrix {
                agent { label DISTROMAP["${DIRSTO}"]['label'] }
                axes {
                    axis {
                        name "DIRSTO"
                        values "oE2309-x86_64", "jammy-x86_64", "fedora38-x86_64", "revyos-riscv64", 'oE2309-riscv64'
                    }
                }
                
                stages {
                    stage('mugen') {
                        steps {
                            echo "Start mugen test on ${DIRSTO}"
                            mugen_install()
                            mugen_run()
                            sh "mv ruyi-test-logs.tar.gz ruyi-test-${DIRSTO}-logs.tar.gz"
                            sh "mv ruyi-test-logs_failed.tar.gz ruyi-test-${DIRSTO}-logs_failed.tar.gz"
                        }
                    }
                }
                
                post {
                    always {
                        archiveArtifacts artifacts: "ruyi-test-*.tar.gz"
                        cleanWs()
                    }
                }
            }
        }
    }
}

