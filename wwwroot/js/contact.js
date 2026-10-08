// Copies the contact email for buttons marked data-copy-text, then confirms on the button.
document.addEventListener('click', async (event) => {
    const button = event.target.closest('[data-copy-text]');
    if (!button) return;

    const label = button.dataset.label ?? button.textContent;
    button.dataset.label = label;
    try {
        await navigator.clipboard.writeText(button.dataset.copyText);
        button.textContent = 'Copied!';
    } catch {
        button.textContent = 'Select and copy above';
    }
    setTimeout(() => { button.textContent = label; }, 2000);
});
