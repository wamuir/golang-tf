# MIT License
# 
# Copyright (c) 2021 William Muir
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ==============================================================================


if ! echo $(go env GOPROXY) | grep -q "^file://${GOPATH}/src/cache[,|$]"; then
	GOPROXY="file://${GOPATH}/src/cache,$(go env GOPROXY)"
	go env -w GOPROXY=${GOPROXY} &> /dev/null || export GOPROXY
fi

if ! echo $(go env GONOSUMDB) | grep -q "github.com/tensorflow/tensorflow[,|$]"; then
	GONOSUMDB="github.com/tensorflow/tensorflow,$(go env GONOSUMDB)"
	go env -w GONOSUMDB=${GONOSUMDB} &> /dev/null || export GONOSUMDB
fi

# return if not interactive
[ -z "$PS1" ] && return

export PS1="${debian_chroot:+($debian_chroot)}\u@golang-tf:\w\$ "
export TERM=xterm-256color

echo -e "\e[1;34m"
cat<<GO
      _____ _____          _____                        ______ _
 ___ |  __ \  _  |    _   |_   _|                       |  ___| |
____ | |  \/ | | |  _| |_   | | ___ _ __  ___  ___  _ __| |_  | | _____      __
  __ | | __| | | | |_ - _|  | |/ _ \ '_ \/ __|/ _ \| '__|  _| | |/ _ \ \ /\ / /
     | |_\ \ \_/ /   |_|    | |  __/ | | \__ \ (_) | |  | |   | | (_) \ V  V /
      \____/\___/           \_/\___|_| |_|___/\___/|_|  \_|   |_|\___/ \_/\_/
GO
echo -e "\e[m"

. /etc/os-release
echo -e "\e[0;34m"
printf "  %s %s %s\n" "$PRETTY_NAME"  "$(uname -r)" "$(uname -m)"
printf "  -------------------------------------------------------------------------------\n"
printf "  * Golang Version:     %s\n" "$GOLANG_VERSION"
printf "  * TensorFlow Version: %s%s\n" "$TENSORFLOW_VERS" "$TENSORFLOW_VERS_SUFFIX"
printf "\n"
echo -e "\e[m"
