alias Hologram.Router.PageModuleResolver
alias Hologram.Runtime.AssetManifestCache
alias Hologram.Runtime.AssetPathRegistry
alias Hologram.Runtime.PageDigestRegistry

# Create tmp dir if it doesn't exist yet.
tmp_path = "#{File.cwd!()}/tmp"
File.mkdir_p!(tmp_path)

ExUnit.start()

Mox.defmock(AssetManifestCacheMock, for: AssetManifestCache)
Application.put_env(:hologram, :asset_manifest_cache_impl, AssetManifestCacheMock)

Mox.defmock(AssetPathRegistryMock, for: AssetPathRegistry)
Application.put_env(:hologram, :asset_path_registry_impl, AssetPathRegistryMock)

Mox.defmock(PageModuleResolverMock, for: PageModuleResolver)
Application.put_env(:hologram, :page_module_resolver_impl, PageModuleResolverMock)

Mox.defmock(PageDigestRegistryMock, for: PageDigestRegistry)
Application.put_env(:hologram, :page_digest_registry_impl, PageDigestRegistryMock)
