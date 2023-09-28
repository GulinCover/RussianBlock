return {
    --匹配规则
    rank_num_match_rule = {
        [1] = {0,300},
        [2] = {301,600},
        [3] = {601,900},
        [4] = {901,1200},
        [5] = {1201,1500},
        [6] = {1501,1800},
        [7] = {1801,99999},
    },

    --集群
    cluster = {
        node1 = "127.0.0.1:7771",
        node2 = "127.0.0.1:7772",
    },
    --agentmgr
    agentmgr = {
        node = "node1"
    },
    --roommgr
    roommgr = {
        node = "node1"
    },
    --scene
    scene = {
        node1 = {1001, 1002},
        -- node2 = {1003},
    },
    --节点数量
    node_id = {'node1','node2'},
    --节点1
    node1 = {
        gateway = {
            [1] = {port=8001},
            [2] = {port=8002},
        },
        login = {
            [1] = {},
            [2] = {},
        },
        db = {
            host = "127.0.0.1",
            port = 3306,
            user = "root",
            password = "ACDCacdc120",
            database = "skynet",
            charset = "utf8mb4"
        }
    },
    --节点2
    node2 = {
        gateway = {
            [1] = {port=8011},
            [2] = {port=8022},
        },
        login = {
            [1] = {},
            [2] = {},
        },
        db = {
            
        }
    },
}