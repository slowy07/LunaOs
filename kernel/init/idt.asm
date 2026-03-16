; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

struc KERNEL_STRUCTURE_IDT_HEADER
  .limit resb 2
  .address resb 8
endstruc

kernel_init_idt:
  call kernel_memory_alloc_page
  jc kernel_init_panic_low_memory

  call kernel_page_drain
  mov qword [kernel_idt_header + KERNEL_STRUCTURE_IDT_HEADER.address], rdi

  mov rax, kernel_idt_exception_default
  mov bx, KERNEL_IDT_TYPE_exception
  mov ecx, 32
  call kernel_idt_update

  mov rax, 255
  mov bx, KERNEL_IDT_TYPE_irq
  mov rdi, kernel_idt_spurious_interrupt
  call kernel_idt_mount

  lidt [kernel_idt_header]

  sti
