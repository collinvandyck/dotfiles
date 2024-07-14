use crate::tui;
use color_eyre::config::HookBuilder;
use color_eyre::eyre;

pub fn install_hooks() -> color_eyre::Result<()> {
    let (panic_hook, eyre_hook) = HookBuilder::default().into_hooks();

    // convert from color_eyre hook into std panic hook
    let panic_hook = panic_hook.into_panic_hook();
    std::panic::set_hook(Box::new(move |panic_info| {
        tui::restore().unwrap();
        panic_hook(panic_info);
    }));

    // convert form a color_eyre EyreHook into an eyre ErrorHook
    let eyre_hook = eyre_hook.into_eyre_hook();
    eyre::set_hook(Box::new(
        move |error: &(dyn std::error::Error + 'static)| {
            tui::restore().unwrap();
            eyre_hook(error)
        },
    ))?;

    Ok(())
}
