"""
ResearchClaw alias package redirecting to findwell.
"""
import findwell

__path__ = findwell.__path__
__version__ = getattr(findwell, "__version__", "0.5.0")

for attr in dir(findwell):
    if not attr.startswith("__"):
        globals()[attr] = getattr(findwell, attr)
