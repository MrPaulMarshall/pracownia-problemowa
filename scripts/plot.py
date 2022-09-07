def optimize(x, y):
    import numpy as np

    X2 = np.sum(x**2)
    X = np.sum(x)
    n = len(x)
    X_1 = np.sum(1/x)
    X_2 = np.sum(1/x**2)

    XY = np.sum(x * y)
    Y = np.sum(y)
    X_1Y = np.sum(y / x)

    A = np.array([
        [X_2, X_1, n],
        [X_1, n, X],
        [n, X, X2]
    ])

    b = np.array([
        [X_1Y],
        [Y],
        [XY]
    ])

    v = np.linalg.inv(A) @ b

    return v[0,0], v[1,0], v[2,0]

def draw_plot(f, x, y, path, primaries):
    import numpy as np
    import matplotlib.pyplot as plt

    # generate prediction line
    fx = np.linspace(x[0], x[-1], 100)
    fy = f(fx)

    # plot prediction line and actual measurments
    plt.title(f'Execution time for {primaries} particles')
    plt.xlabel('Number of CPUs')
    plt.ylabel('Execution time [s]')

    plt.xticks(x)

    plt.plot(fx, fy, linewidth=1.0, linestyle='--', label='Prediction line')
    plt.scatter(x, y, c='#ff0000', label='Measurments')

    plt.legend()
    plt.savefig(path)

def main(csv_path, image_path, primaries):
    import numpy as np
    
    x, y = np.genfromtxt(csv_path, skip_header=1, delimiter=',', unpack=True)

    a, b, c = optimize(x, y)
    print(f'Optimal coefficients: {a=} {b=} {c=}\n')

    def f(t):
        return a/t + b + c*t
    
    draw_plot(f, x, y, image_path, primaries)

if __name__ == '__main__':
    import sys
    if len(sys.argv) != 4:
        sys.exit(f'Invalid list of arguments: {sys.argv}; expected 3 arguments - <input>.csv <output>.png <particles-no>')
    if int(sys.argv[3]) <= 0:
        sys.exit(f'Number of particles should be positive integer; instead is {sys.argv[3]}')

    main(sys.argv[1], sys.argv[2], int(sys.argv[3]))
