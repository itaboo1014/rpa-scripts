# readonly GIT_REPOSITORY_PATH=/var/www/eccube

# PRODUCTION_FLAG=0
# case ${HOSTNAME} in
#     *-production-*)
#         GIT_BRANCH=master
#         ENV=本番
#         PRODUCTION_FLAG=1
#     ;;
#     *-staging-*)
#         GIT_BRANCH=master
#         ENV=検証
#     ;;
#     *-development-*)
#         GIT_BRANCH=develop
#         ENV=開発
#     ;;
#     *)
#         exit 1
#     ;;
# esac

# ECCUBE_FLAG=0
# case ${HOSTNAME} in
#     *-admin-*)
#         ECCUBE_FLAG=1
#     ;;
# esac

readonly ENV=本番 # リリース対象の環境 本番/検証/開発
readonly GIT_BRANCH=master # リリース対象のブランチ master/develop
readonly ECCUBE_FLAG=1 # リリース対象がEC-CUBE 4 かどうか 0/1
readonly PRODUCTION_FLAG=1 # リリース対象の環境が本番かどうか 0/1
readonly GIT_REPOSITORY_PATH=. # Gitリポジトリのルートディレクトリパス

#!/bin/bash
set -e
set -u
# set -x

_hr(){
    printf '\n'
    printf '=%.0s' {1..80}
    printf '\n\n'
}

_hr
read -p "${ENV}環境のリリース作業を開始します。プロジェクトに作業の開始を周知し、 Enter を押してください。 (Ctrl+C で中断できます): "

_hr
(
    set -x
    git -C ${GIT_REPOSITORY_PATH} rev-parse --abbrev-ref HEAD
)

_hr
read -p "${GIT_BRANCH} ブランチに checkout していることを確認し、 Enter を押してください。 (Ctrl+C で中断できます): "

_hr
(
    set -x
    git -C ${GIT_REPOSITORY_PATH} status
)

_hr
read -p "ワーキングツリーがクリーンであることを確認し、 Enter を押してください。 (Ctrl+C で中断できます): "

_hr
(
    set -x
    git -C ${GIT_REPOSITORY_PATH} fetch --prune
    git -C ${GIT_REPOSITORY_PATH} log --oneline --no-merges HEAD..origin/${GIT_BRANCH}
)

_hr
read -p "リリースするコミットを確認し、 Enter を押してください。 (Ctrl+C で中断できます): "

_hr
read -p "デプロイを実行します。よろしければ Enter を押してください。 (Ctrl+C で中断できます): "

_hr
(
    set -x
    git -C ${GIT_REPOSITORY_PATH} merge origin/${GIT_BRANCH}
    git -C ${GIT_REPOSITORY_PATH} log --oneline --no-merges HEAD..origin/${GIT_BRANCH}
)

_hr
read -p "未リリースのコミットの差分が存在しない（何も表示されない）ことを確認してください。よろしければ Enter を押してください。 (Ctrl+C で中断できます): "

if ((ECCUBE_FLAG))
then
    _hr
    read -p "EC-CUBEコマンドを実行します。よろしければ Enter を押してください。 (Ctrl+C で中断できます): "

    _hr
    (
        php ${GIT_REPOSITORY_PATH}/bin/console eccube:generate:proxies
        php ${GIT_REPOSITORY_PATH}/bin/console cache:clear --no-warmup
        php ${GIT_REPOSITORY_PATH}/bin/console doctrine:schema:update --dump-sql --force
        php ${GIT_REPOSITORY_PATH}/bin/console doctrine:migration:migrate -n
    )
fi

date

_hr
(
cat <<!
    *** フロントを確認し、リリース作業の完了をプロジェクトに周知してください。 ***
!
)

if ((PRODUCTION_FLAG))
then
_hr
(
cat <<!
    *** ローカルから最新の ${GIT_BRANCH} ブランチにタグを付与してください。 ***

    git tag -a -m '本番リリース' $(date +%Y%m%d%H%M) $(git -C ${GIT_REPOSITORY_PATH} rev-parse HEAD)
    git push origin $(date +%Y%m%d%H%M)
!
)
fi
