document.addEventListener('DOMContentLoaded', function() {
    d3.csv(
        'https://raw.githubusercontent.com/athanclark/intset.js/main/bench/results.csv',
        function(err, rows){
            // [[x]] -> [x_i]
            const unpack = function unpack(key) {
                return rows.map(function(row) { return row[key]; });
            };
            const defScene = {
                xaxis: {
                    title: 'n=2^x'
                },
                yaxis: {
                    title: 'max=2^y'
                }
            };
            const defPlotParams = {
                autosize: false,
                width: 500,
                height: 500,
                margin: {
                    l: 65,
                    r: 50,
                    b: 65,
                    t: 90,
                }
            };
            (() => {
                const reductionX = function reductionX(xs) {
                    return xs;
                };
                const reductionY = function reductionY(ys) {
                    // return ys.slice(0,5);
                    return ys;
                };
                const defParams = {
                    x: reductionX(mkX()),
                    y: reductionY(mkY()),
                    mode: 'markers',
                    marker: {
                        size: 12,
                        line: {
                            color: 'rgba(217, 217, 217, 0.14)',
                            width: 0.5
                        },
                        opacity: 0.8
                    },
                    type: 'surface'
                };
                const opsPerSec = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('ops_per_sec'))).map(reductionX)
                };
                const heapUsed = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('heap_used'))).map(reductionX)
                };
                const totalSize = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('total_size'))).map(reductionX)
                };

                Plotly.newPlot('ops-per-sec', [opsPerSec], {
                    ...defPlotParams,
                    title: 'Operations Per Second',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'ops/sec'
                        }
                    }
                });

                Plotly.newPlot('heap-used', [heapUsed], {
                    ...defPlotParams,
                    title: 'Heap Used',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'heap used'
                        }
                    }
                });

                Plotly.newPlot('total-size', [totalSize], {
                    ...defPlotParams,
                    title: 'Total Size',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'total size'
                        }
                    }
                });
            })();
            (() => {
                const reductionX = function reductionX(xs) {
                    return xs.slice(0,8);
                };
                const reductionY = function reductionY(ys) {
                    return ys.slice(0,5);
                };
                const defParams = {
                    x: reductionX(mkX()),
                    y: reductionY(mkY()),
                    mode: 'markers',
                    marker: {
                        size: 12,
                        line: {
                            color: 'rgba(217, 217, 217, 0.14)',
                            width: 0.5
                        },
                        opacity: 0.8
                    },
                    type: 'surface'
                };
                const opsPerSec = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('ops_per_sec'))).map(reductionX)
                };
                const heapUsed = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('heap_used'))).map(reductionX)
                };
                const totalSize = {
                    ...defParams,
                    z: reductionY(chunkBy11(unpack('total_size'))).map(reductionX)
                };

                Plotly.newPlot('reduced-ops-per-sec', [opsPerSec], {
                    ...defPlotParams,
                    title: 'Operations Per Second',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'ops/sec'
                        }
                    }
                });

                Plotly.newPlot('reduced-heap-used', [heapUsed], {
                    ...defPlotParams,
                    title: 'Heap Used',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'heap used'
                        }
                    }
                });

                Plotly.newPlot('reduced-total-size', [totalSize], {
                    ...defPlotParams,
                    title: 'Total Size',
                    scene: {
                        ...defScene,
                        zaxis: {
                            title: 'total size'
                        }
                    }
                });
            })();
        }
    );
});

function mkX() {
    let result = [];
    for (let i = 5; i <= 15; i++) {
        result.push(i.toString());
    }
    return result;
}

function mkY() {
    let result = [];
    for (let i = 8; i <= 32; i += 4) {
        result.push(i.toString());
    }
    return result;
}

function chunkBy11(xs) {
    let result = [];
    for (let i = 0; i < xs.length; i += 11) {
        result.push(xs.slice(i, i+11));
    }
    return result;
}
