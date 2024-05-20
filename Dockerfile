#   Copyright (c) 2024 YottaDB LLC
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM yottadb/yottadb-base:latest-master

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y git cmake make pkg-config libicu-dev libcurl4-openssl-dev

# Download YDBCMake
RUN git clone https://gitlab.com/YottaDB/Tools/YDBCMake.git

# Install YDBCurl
COPY r/ r/
COPY libcurl.c .
COPY libcurl.xc.in .

COPY CMakeLists.txt .
RUN mkdir build && cd build && cmake -D FETCHCONTENT_SOURCE_DIR_YDBCMAKE=../YDBCMake .. && make
WORKDIR /data/build

ENTRYPOINT ["make", "test","ARGS=\"-V\""]

