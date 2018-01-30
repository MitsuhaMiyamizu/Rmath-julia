using BinaryBuilder

# These are the platforms built inside the wizard
platforms = [
    BinaryProvider.Linux(:i686, :glibc),
  BinaryProvider.Linux(:x86_64, :glibc),
  BinaryProvider.Linux(:aarch64, :glibc),
  BinaryProvider.Linux(:armv7l, :glibc),
  BinaryProvider.Linux(:powerpc64le, :glibc),
  BinaryProvider.MacOS(),
  BinaryProvider.Windows(:i686),
  BinaryProvider.Windows(:x86_64)
]


# If the user passed in a platform (or a few, comma-separated) on the
# command-line, use that instead of our default platforms
if length(ARGS) > 0
    platforms = platform_key.(split(ARGS[1], ","))
end
info("Building for $(join(triplet.(platforms), ", "))")

# Collection of sources required to build rmath.
# On travis we build a tagged release by default.
if isempty(get(ENV, "TRAVIS_TAG", ""))
sources = [
    "https://github.com/JuliaLang/Rmath-julia/archive/v0.2.0.tar.gz" =>
    "087ada2913c5401c5772cde1606f9924dcb159f1c9d755630dcce350ef8036ac",
]
else
sha = readstring(`git rev-list -n 1 $(ENV["TRAVIS_TAG"])`)
sources = [
    "https://github.com/JuliaStats/Rmath-julia.git" =>
    ENV["TRAVIS_TAG"],
]
end

script = raw"""
cd $WORKSPACE/srcdir
cd Rmath-julia-0.2.0/
make
if [[ ${target} == *-mingw32 ]]; then
    mkdir $DESTDIR/bin
    mv src/libRmath-julia.* $DESTDIR/bin
else
    mkdir $DESTDIR/lib
    mv src/libRmath-julia.* $DESTDIR/lib
fi
"""

products = prefix -> [
    LibraryProduct(prefix,"libRmath-julia")
]


# Build the given platforms using the given sources
hashes = autobuild(pwd(), "rmath", platforms, sources, script, products)

if !isempty(get(ENV,"TRAVIS_TAG",""))
    print_buildjl(pwd(), products, hashes,
        "https://github.com/JuliaStats/Rmath-julia/releases/download/$(ENV["TRAVIS_TAG"])")
end
