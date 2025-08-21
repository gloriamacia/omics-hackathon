FROM public.ecr.aws/amazonlinux/amazonlinux:2
RUN yum -y install shadow-utils findutils which coreutils gzip tar bash && yum clean all
WORKDIR /opt/app
